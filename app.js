function createElementRow(index) {
  const tr = document.createElement('tr');
  tr.innerHTML = `
    <td class="el-index">${index}</td>
    <td><input type="number" min="1" class="el-ni" value="${index}"></td>
    <td><input type="number" min="1" class="el-nj" value="${index + 1}"></td>
    <td><input type="number" step="any" class="el-I" value="0.0241"></td>
    <td><input type="number" step="any" class="el-A" value="1.66"></td>
    <td><input type="number" step="any" class="el-L" value="5.00"></td>
    <td><input type="number" step="any" class="el-pa" value="0.00"></td>
    <td><input type="number" step="any" class="el-pb" value="0.00"></td>
    <td><button type="button" class="remove-btn">X</button></td>
  `;
  return tr;
}

function createSupportRow() {
  const tr = document.createElement('tr');
  tr.innerHTML = `
    <td><input type="number" min="1" class="sup-node"></td>
    <td>
      <select class="sup-kx">
        <option value="0">0 (libre)</option>
        <option value="1">1 (fijo)</option>
      </select>
    </td>
    <td>
      <select class="sup-ky">
        <option value="0">0 (libre)</option>
        <option value="1" selected>1 (fijo)</option>
      </select>
    </td>
    <td>
      <select class="sup-kr">
        <option value="0" selected>0 (libre)</option>
        <option value="1">1 (fijo)</option>
      </select>
    </td>
    <td><button type="button" class="remove-btn">X</button></td>
  `;
  return tr;
}

function createFyRow() {
  const tr = document.createElement('tr');
  tr.innerHTML = `
    <td><input type="number" min="1" class="fy-node"></td>
    <td><input type="number" step="any" class="fy-val"></td>
    <td><button type="button" class="remove-btn">X</button></td>
  `;
  return tr;
}

function renumberElements() {
  const rows = document.querySelectorAll('#elements-table tbody tr');
  rows.forEach((tr, idx) => {
    const cell = tr.querySelector('.el-index');
    if (cell) cell.textContent = (idx + 1).toString();
  });
}

/* ----------------- DIBUJO DEL MODELO EN CANVAS ----------------- */

function drawModel() {
  const canvas = document.getElementById('modelCanvas');
  if (!canvas || !canvas.getContext) return;
  const ctx = canvas.getContext('2d');
  const w = canvas.width;
  const h = canvas.height;

  ctx.clearRect(0, 0, w, h);
  ctx.font = '11px system-ui';

  const elementsTbody = document.querySelector('#elements-table tbody');
  const supportsTbody = document.querySelector('#supports-table tbody');
  const fyTbody = document.querySelector('#fy-table tbody');

  // Leer elementos
  const elements = [];
  const nodeSet = new Set();

  Array.from(elementsTbody.querySelectorAll('tr')).forEach(tr => {
    const ni = parseInt(tr.querySelector('.el-ni').value || '0', 10);
    const nj = parseInt(tr.querySelector('.el-nj').value || '0', 10);
    if (!ni || !nj) return;
    elements.push({ ni, nj });
    nodeSet.add(ni);
    nodeSet.add(nj);
  });

  if (elements.length === 0 || nodeSet.size === 0) {
    ctx.fillStyle = '#555';
    ctx.fillText('Añade elementos para ver el modelo.', 20, h / 2);
    return;
  }

  // Ordenar nodos y asignar posiciones en X (no a escala, pero en orden)
  const nodes = Array.from(nodeSet).sort((a, b) => a - b);
  const marginX = 40;
  const span = nodes.length > 1 ? (w - 2 * marginX) / (nodes.length - 1) : 0;
  const baseY = h / 2;

  const nodePos = {};
  nodes.forEach((n, i) => {
    nodePos[n] = marginX + span * i;
  });

  // Dibujar elementos (viga)
  ctx.strokeStyle = '#111';
  ctx.lineWidth = 3;
  ctx.beginPath();
  elements.forEach(el => {
    const x1 = nodePos[el.ni];
    const x2 = nodePos[el.nj];
    if (x1 == null || x2 == null) return;
    ctx.moveTo(x1, baseY);
    ctx.lineTo(x2, baseY);
  });
  ctx.stroke();

  // Dibujar nodos
  nodes.forEach(n => {
    const x = nodePos[n];
    ctx.fillStyle = '#ffffff';
    ctx.strokeStyle = '#111';
    ctx.lineWidth = 1.5;
    ctx.beginPath();
    ctx.arc(x, baseY, 6, 0, Math.PI * 2);
    ctx.fill();
    ctx.stroke();

    ctx.fillStyle = '#111';
    ctx.fillText(String(n), x - 3, baseY - 10);
  });

  // Leer apoyos
  const supports = [];
  Array.from(supportsTbody.querySelectorAll('tr')).forEach(tr => {
    const node = parseInt(tr.querySelector('.sup-node').value || '0', 10);
    const kx = parseInt(tr.querySelector('.sup-kx').value || '0', 10);
    const ky = parseInt(tr.querySelector('.sup-ky').value || '0', 10);
    const kr = parseInt(tr.querySelector('.sup-kr').value || '0', 10);
    if (!node) return;
    supports.push({ node, kx, ky, kr });
  });

  // Dibujar apoyos como triángulos debajo del nodo si tienen ky fijo
  ctx.fillStyle = '#1d4ed8';
  ctx.strokeStyle = '#1d4ed8';
  supports.forEach(s => {
    const x = nodePos[s.node];
    if (x == null) return;

    // Si hay fijación vertical (ky=1), dibujamos un triángulo
    if (s.ky === 1) {
      const yTop = baseY + 8;
      ctx.beginPath();
      ctx.moveTo(x - 10, yTop);
      ctx.lineTo(x + 10, yTop);
      ctx.lineTo(x, yTop + 14);
      ctx.closePath();
      ctx.fill();
    }

    // Si también hay fijación horizontal (kx=1), añadimos un rectángulo pequeño
    if (s.kx === 1) {
      ctx.fillRect(x - 3, baseY + 22, 6, 8);
    }

    // Si la rotación está fija (kr=1), marcamos un pequeño círculo
    if (s.kr === 1) {
      ctx.beginPath();
      ctx.arc(x, baseY - 14, 3, 0, Math.PI * 2);
      ctx.fill();
    }
  });

  // Leer cargas en Y
  const loadsFy = [];
  Array.from(fyTbody.querySelectorAll('tr')).forEach(tr => {
    const node = parseInt(tr.querySelector('.fy-node').value || '0', 10);
    const val  = parseFloat(tr.querySelector('.fy-val').value || '0');
    if (!node || Math.abs(val) < 1e-9) return;
    loadsFy.push({ node, val });
  });

  // Dibujar cargas como flechas (hacia abajo si val < 0, hacia arriba si val > 0)
  ctx.strokeStyle = '#b91c1c';
  ctx.fillStyle = '#b91c1c';
  loadsFy.forEach(L => {
    const x = nodePos[L.node];
    if (x == null) return;

    const down = L.val < 0; // si negativo, dibujamos hacia abajo
    const len = 26;
    const y0 = baseY + (down ? -len : len);
    const y1 = baseY + (down ? -6 : 6);

    // Línea de la flecha
    ctx.beginPath();
    ctx.moveTo(x, y0);
    ctx.lineTo(x, y1);
    ctx.stroke();

    // Cabeza de flecha
    ctx.beginPath();
    if (down) {
      ctx.moveTo(x - 5, y1 - 5);
      ctx.lineTo(x, y1);
      ctx.lineTo(x + 5, y1 - 5);
    } else {
      ctx.moveTo(x - 5, y1 + 5);
      ctx.lineTo(x, y1);
      ctx.lineTo(x + 5, y1 + 5);
    }
    ctx.stroke();

    // Texto de magnitud
    const txt = L.val.toFixed(2);
    ctx.fillText(txt, x + 6, y0 + (down ? -4 : 12));
  });
}

/* ----------------- LÓGICA PRINCIPAL DEL WIZARD ----------------- */

function setup() {
  const elementsTbody = document.querySelector('#elements-table tbody');
  const supportsTbody = document.querySelector('#supports-table tbody');
  const fyTbody = document.querySelector('#fy-table tbody');
  const preview = document.querySelector('#preview');

  // Añadir elemento
  document.querySelector('#btn-add-element').addEventListener('click', () => {
    const index = elementsTbody.querySelectorAll('tr').length + 1;
    elementsTbody.appendChild(createElementRow(index));
    drawModel();
  });

  // Añadir soporte
  document.querySelector('#btn-add-support').addEventListener('click', () => {
    supportsTbody.appendChild(createSupportRow());
    drawModel();
  });

  // Añadir carga en Y
  document.querySelector('#btn-add-fy').addEventListener('click', () => {
    fyTbody.appendChild(createFyRow());
    drawModel();
  });

  // Botones X (eliminar filas)
  document.body.addEventListener('click', (e) => {
    if (e.target.classList.contains('remove-btn')) {
      const tr = e.target.closest('tr');
      const tbody = tr && tr.parentElement;
      if (tr && tbody) {
        tbody.removeChild(tr);
        if (tbody.id === 'elements-table') {
          renumberElements();
        } else if (tbody.parentElement && tbody.parentElement.id === 'elements-table') {
          renumberElements();
        }
        drawModel();
      }
    }
  });

  // Redibujar cuando cambie algo en las tablas
  document.body.addEventListener('input', (e) => {
    if (
      e.target.classList.contains('el-ni') ||
      e.target.classList.contains('el-nj') ||
      e.target.classList.contains('el-L') ||
      e.target.classList.contains('sup-node') ||
      e.target.classList.contains('sup-kx') ||
      e.target.classList.contains('sup-ky') ||
      e.target.classList.contains('sup-kr') ||
      e.target.classList.contains('fy-node') ||
      e.target.classList.contains('fy-val')
    ) {
      drawModel();
    }
  });

  // Generar archivo
  document.querySelector('#btn-generate').addEventListener('click', () => {
    const txt = generateTxt();
    preview.textContent = txt;
    const filename = document.querySelector('#filename').value || 'acera.txt';
    downloadFile(filename, txt);
  });

  // Dibujo inicial vacío
  drawModel();
}

function generateTxt() {
  const desc = (document.querySelector('#desc').value || 'Caso ZAPEL').trim();
  const ela = parseFloat(document.querySelector('#ela').value || '0');
  const jbwInput = document.querySelector('#jbw').value;

  const elementsTbody = document.querySelector('#elements-table tbody');
  const supportsTbody = document.querySelector('#supports-table tbody');
  const fyTbody = document.querySelector('#fy-table tbody');

  const elements = [];
  let maxSpan = 0;
  let maxNode = 0;

  // 1) Leer elementos
  Array.from(elementsTbody.querySelectorAll('tr')).forEach((tr, idx) => {
    const ni = parseInt(tr.querySelector('.el-ni').value || '1', 10);
    const nj = parseInt(tr.querySelector('.el-nj').value || '1', 10);
    const I  = parseFloat(tr.querySelector('.el-I').value || '0');
    const A  = parseFloat(tr.querySelector('.el-A').value || '0');
    const L  = parseFloat(tr.querySelector('.el-L').value || '0');
    const pa = parseFloat(tr.querySelector('.el-pa').value || '0');
    const pb = parseFloat(tr.querySelector('.el-pb').value || '0');

    const span = Math.abs(nj - ni);
    if (span > maxSpan) maxSpan = span;

    if (ni > maxNode) maxNode = ni;
    if (nj > maxNode) maxNode = nj;

    elements.push({ mem: idx + 1, ni, nj, I, A, L, pa, pb });
  });

  const nm = elements.length;

  // 2) Leer soportes
  const supports = [];
  Array.from(supportsTbody.querySelectorAll('tr')).forEach(tr => {
    const node = parseInt(tr.querySelector('.sup-node').value || '1', 10);
    const kx = parseInt(tr.querySelector('.sup-kx').value || '0', 10);
    const ky = parseInt(tr.querySelector('.sup-ky').value || '0', 10);
    const kr = parseInt(tr.querySelector('.sup-kr').value || '0', 10);

    if (node > maxNode) maxNode = node;

    supports.push({ node, kx, ky, kr });
  });
  const na = supports.length;

  // 3) Leer cargas en Y
  const loadsFy = [];
  Array.from(fyTbody.querySelectorAll('tr')).forEach(tr => {
    const node = parseInt(tr.querySelector('.fy-node').value || '1', 10);
    const val  = parseFloat(tr.querySelector('.fy-val').value || '0');

    if (node > maxNode) maxNode = node;
    if (Math.abs(val) > 1e-9) {
      loadsFy.push({ node, val });
    }
  });
  const nca2 = loadsFy.length;

  const nn = maxNode === 0 ? 1 : maxNode;

  // 4) Parámetros globales
  let jbw;
  if (jbwInput) {
    jbw = parseInt(jbwInput, 10);
  } else {
    jbw = 3 + 3 * maxSpan;
  }

  const nspd = 0;
  // Estos tres los ponemos como en el archivo "bueno": 1 0 0
  const nca1 = 1;
  const nca3 = 0;

  const lines = [];

  // Línea 1: número de casos
  lines.push('1');

  // Línea 2: descripción
  lines.push(desc);

  // Línea 3: global (igual estructura que el acera.txt largo)
  // nm  nn  na  nspd  jbw  1  0  0  Ela
  lines.push(
    `${nm}   ${nn}   ${na}   ${nspd}   ${jbw}   ${nca1}   0   ${nca3} ${Number(ela).toExponential(4)}`
  );

  // 5) Líneas de elementos en formato largo:
  // mem  ni  nj  I  A  L   0  0.000  0.000  pa  pb  0.00  0.00  0.00 00
  elements.forEach(el => {
    const Istr  = Number(el.I).toFixed(5);   // 0.02400
    const Astr  = Number(el.A).toFixed(2);   // 1.66
    const Lstr  = Number(el.L).toFixed(2);   // 5.00, 10.00
    const pastr = Number(el.pa).toFixed(3);  // -0.250
    const pbstr = Number(el.pb).toFixed(3);  // -0.250

    const line =
      `${el.mem}   ${el.ni}   ${el.nj}` +
      `  ${Istr}` +
      `   ${Astr}` +
      `   ${Lstr}` +
      `      0` +
      `  0.000  0.000` +           // campos intermedios que dejamos en 0
      `  ${pastr} ${pbstr}` +      // aquí metemos pa y pb
      `    0.00   0.00   0.00 00`; // resto en 0
    lines.push(line);
  });

  // 6) Soportes: 1 por línea, como en el archivo bueno:
  // 1  nodo kx ky kr
  supports.forEach(s => {
    lines.push(
      `1  ${s.node}  ${s.kx}  ${s.ky}  ${s.kr}`
    );
  });

  // 7) Bloques de ceros + cargas, imitando el patrón:
  // 0
  // 0
  // 1 nodo Fy...
  // 0
  // 0

  // primer bloque 0
  lines.push('0');
  // segundo bloque 0
  lines.push('0');

  // bloque de cargas en Y
  if (nca2 > 0) {
    // Ejemplo: 1  2    2.47
    let fyLine = `${nca2}`;
    loadsFy.forEach(L => {
      fyLine += `  ${L.node}   ${Number(L.val).toFixed(2)}`;
    });
    lines.push(fyLine);
  } else {
    // si no hay cargas, ponemos 0
    lines.push('0');
  }

  // últimos dos bloques 0
  lines.push('0');
  lines.push('0');

  return lines.join('\n');
}


function downloadFile(filename, content) {
  const blob = new Blob([content], { type: 'text/plain' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = filename;
  document.body.appendChild(a);
  a.click();
  a.remove();
  URL.revokeObjectURL(url);
}

document.addEventListener('DOMContentLoaded', setup);
