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

/* --------- UTIL: quitar 0 a la izquierda en .xxxx --------- */

function noLeadingZeroDecimal(num, decimals) {
  let s = Number(num).toFixed(decimals);
  if (s.startsWith("0.")) {
    return s.slice(1);
  } else if (s.startsWith("-0.")) {
    return "-" + s.slice(2);
  }
  return s;
}

/* --------- DIBUJO DEL MODELO EN CANVAS --------- */

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

  const elements = [];
  const nodeSet = new Set();

  // 🔹 LEER ELEMENTOS (ahora también pa y pb)
  Array.from(elementsTbody.querySelectorAll('tr')).forEach(tr => {
    const ni = parseInt(tr.querySelector('.el-ni').value || '0', 10);
    const nj = parseInt(tr.querySelector('.el-nj').value || '0', 10);
    const pa = parseFloat(tr.querySelector('.el-pa').value || '0');
    const pb = parseFloat(tr.querySelector('.el-pb').value || '0');
    if (!ni || !nj) return;
    elements.push({ ni, nj, pa, pb });
    nodeSet.add(ni);
    nodeSet.add(nj);
  });

  if (elements.length === 0 || nodeSet.size === 0) {
    ctx.fillStyle = '#555';
    ctx.fillText('Añade elementos para ver el modelo.', 20, h / 2);
    return;
  }

  const nodes = Array.from(nodeSet).sort((a, b) => a - b);
  const marginX = 40;
  const span = nodes.length > 1 ? (w - 2 * marginX) / (nodes.length - 1) : 0;
  const baseY = h / 2;

  const nodePos = {};
  nodes.forEach((n, i) => {
    nodePos[n] = marginX + span * i;
  });

  // 🔹 DIBUJAR ELEMENTOS (linea de la viga)
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

  // 🔹 NODOS
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

  // 🔹 SOPORTES
  const supports = [];
  Array.from(supportsTbody.querySelectorAll('tr')).forEach(tr => {
    const node = parseInt(tr.querySelector('.sup-node').value || '0', 10);
    const kx = parseInt(tr.querySelector('.sup-kx').value || '0', 10);
    const ky = parseInt(tr.querySelector('.sup-ky').value || '0', 10);
    const kr = parseInt(tr.querySelector('.sup-kr').value || '0', 10);
    if (!node) return;
    supports.push({ node, kx, ky, kr });
  });

  ctx.fillStyle = '#1d4ed8';
  ctx.strokeStyle = '#1d4ed8';
  supports.forEach(s => {
    const x = nodePos[s.node];
    if (x == null) return;

    if (s.ky === 1) {
      const yTop = baseY + 8;
      ctx.beginPath();
      ctx.moveTo(x - 10, yTop);
      ctx.lineTo(x + 10, yTop);
      ctx.lineTo(x, yTop + 14);
      ctx.closePath();
      ctx.fill();
    }

    if (s.kx === 1) {
      ctx.fillRect(x - 3, baseY + 22, 6, 8);
    }

    if (s.kr === 1) {
      ctx.beginPath();
      ctx.arc(x, baseY - 14, 3, 0, Math.PI * 2);
      ctx.fill();
    }
  });

  // 🔹 CARGAS NODALES EN Y (como ya tenías)
  const loadsFy = [];
  Array.from(fyTbody.querySelectorAll('tr')).forEach(tr => {
    const node = parseInt(tr.querySelector('.fy-node').value || '0', 10);
    const val  = parseFloat(tr.querySelector('.fy-val').value || '0');
    if (!node || Math.abs(val) < 1e-9) return;
    loadsFy.push({ node, val });
  });

  ctx.strokeStyle = '#b91c1c';
  ctx.fillStyle = '#b91c1c';
  loadsFy.forEach(L => {
    const x = nodePos[L.node];
    if (x == null) return;

    const down = L.val < 0;
    const len = 26;
    const y0 = baseY + (down ? -len : len);
    const y1 = baseY + (down ? -6 : 6);

    ctx.beginPath();
    ctx.moveTo(x, y0);
    ctx.lineTo(x, y1);
    ctx.stroke();

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

    const txt = L.val.toFixed(2);
    ctx.fillText(txt, x + 6, y0 + (down ? -4 : 12));
  });

  // 🔹 CARGAS DISTRIBUIDAS (pa, pb) SOBRE CADA ELEMENTO
  ctx.strokeStyle = '#b91c1c';
  ctx.fillStyle = '#b91c1c';

  elements.forEach(el => {
    const x1 = nodePos[el.ni];
    const x2 = nodePos[el.nj];
    if (x1 == null || x2 == null) return;

    const pa = el.pa || 0;
    const pb = el.pb || 0;
    const avg = (pa + pb) / 2;

    if (Math.abs(avg) < 1e-9) {
      // Sin carga distribuida significativa
      return;
    }

    const down = avg < 0;  // negativa hacia abajo (como -0.25)
    const nArrows = 4;     // número de flechas sobre el elemento
    const yLine = baseY - 28;      // posición de la "línea" de la carga
    const yBeam = baseY;           // eje de la viga
    const len = 18;                // longitud de flecha

    // Línea base de la carga distribuida
    ctx.beginPath();
    ctx.moveTo(x1 + 8, yLine);
    ctx.lineTo(x2 - 8, yLine);
    ctx.stroke();

    // Flechas distribuidas
    for (let i = 0; i < nArrows; i++) {
      const t = (i + 0.5) / nArrows;
      const x = x1 + (x2 - x1) * t;
      const y0 = down ? yLine : yLine;
      const y1 = down ? yLine + len : yLine - len;

      ctx.beginPath();
      ctx.moveTo(x, y0);
      ctx.lineTo(x, y1);
      ctx.stroke();

      ctx.beginPath();
      if (down) {
        ctx.moveTo(x - 4, y1 - 5);
        ctx.lineTo(x, y1);
        ctx.lineTo(x + 4, y1 - 5);
      } else {
        ctx.moveTo(x - 4, y1 + 5);
        ctx.lineTo(x, y1);
        ctx.lineTo(x + 4, y1 + 5);
      }
      ctx.stroke();
    }

    // Texto de valor promedio
    const label = avg.toFixed(2);
    ctx.fillText(label, (x1 + x2) / 2 + 6, yLine - 4);
  });
}

/* --------- LÓGICA PRINCIPAL --------- */

function setup() {
  const elementsTbody = document.querySelector('#elements-table tbody');
  const supportsTbody = document.querySelector('#supports-table tbody');
  const fyTbody = document.querySelector('#fy-table tbody');
  const preview = document.querySelector('#preview');

  document.querySelector('#btn-add-element').addEventListener('click', () => {
    const index = elementsTbody.querySelectorAll('tr').length + 1;
    elementsTbody.appendChild(createElementRow(index));
    drawModel();
  });

  document.querySelector('#btn-add-support').addEventListener('click', () => {
    supportsTbody.appendChild(createSupportRow());
    drawModel();
  });

  document.querySelector('#btn-add-fy').addEventListener('click', () => {
    fyTbody.appendChild(createFyRow());
    drawModel();
  });

  // Botón cargar ejemplo acera
  document.querySelector('#btn-load-example').addEventListener('click', () => {
    loadAceraExample();
    drawModel();
    const txt = generateTxt();
    preview.textContent = txt;
  });

  // Eliminar filas
  document.body.addEventListener('click', (e) => {
    if (e.target.classList.contains('remove-btn')) {
      const tr = e.target.closest('tr');
      const tbody = tr && tr.parentElement;
      if (tr && tbody) {
        tbody.removeChild(tr);
        if (tbody.parentElement && tbody.parentElement.id === 'elements-table') {
          renumberElements();
        } else if (tbody.id === 'elements-table') {
          renumberElements();
        }
        drawModel();
      }
    }
  });

  // Redibujar al cambiar datos
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

  document.querySelector('#btn-generate').addEventListener('click', () => {
    const txt = generateTxt();
    preview.textContent = txt;
    const filename = document.querySelector('#filename').value || 'caso.txt';
    downloadFile(filename, txt);
  });

  // Estado inicial: sin elementos, dibujo vacío
  drawModel();
}

/* --------- CARGAR EJEMPLO ACERA --------- */

function loadAceraExample() {
  const descInput = document.querySelector('#desc');
  const elaInput  = document.querySelector('#ela');
  const jbwInput  = document.querySelector('#jbw');
  const elementsTbody = document.querySelector('#elements-table tbody');
  const supportsTbody = document.querySelector('#supports-table tbody');
  const fyTbody = document.querySelector('#fy-table tbody');

  descInput.value = 'Caso 2 - Acera Proyecto Vega Baja';
  elaInput.value = '519120.0';
  jbwInput.value = '6';

  elementsTbody.innerHTML = '';
  supportsTbody.innerHTML = '';
  fyTbody.innerHTML = '';

  // Elementos
  const e1 = createElementRow(1);
  e1.querySelector('.el-ni').value = 1;
  e1.querySelector('.el-nj').value = 2;
  e1.querySelector('.el-I').value  = 0.0241;
  e1.querySelector('.el-A').value  = 1.66;
  e1.querySelector('.el-L').value  = 5.0;
  e1.querySelector('.el-pa').value = 0.0;
  e1.querySelector('.el-pb').value = 0.0;

  const e2 = createElementRow(2);
  e2.querySelector('.el-ni').value = 2;
  e2.querySelector('.el-nj').value = 3;
  e2.querySelector('.el-I').value  = 0.0241;
  e2.querySelector('.el-A').value  = 1.66;
  e2.querySelector('.el-L').value  = 5.0;
  e2.querySelector('.el-pa').value = 0.0;
  e2.querySelector('.el-pb').value = 0.0;

  const e3 = createElementRow(3);
  e3.querySelector('.el-ni').value = 3;
  e3.querySelector('.el-nj').value = 4;
  e3.querySelector('.el-I').value  = 0.0241;
  e3.querySelector('.el-A').value  = 1.66;
  e3.querySelector('.el-L').value  = 10.0;
  e3.querySelector('.el-pa').value = -0.25;
  e3.querySelector('.el-pb').value = -0.25;

  elementsTbody.appendChild(e1);
  elementsTbody.appendChild(e2);
  elementsTbody.appendChild(e3);
  renumberElements();

  // Soportes: 3 1 0 1 0 3 1 1 0 4 0 1 0
  const s1 = createSupportRow();
  s1.querySelector('.sup-node').value = 1;
  s1.querySelector('.sup-kx').value   = 0;
  s1.querySelector('.sup-ky').value   = 1;
  s1.querySelector('.sup-kr').value   = 0;

  const s3 = createSupportRow();
  s3.querySelector('.sup-node').value = 3;
  s3.querySelector('.sup-kx').value   = 1;
  s3.querySelector('.sup-ky').value   = 1;
  s3.querySelector('.sup-kr').value   = 0;

  const s4 = createSupportRow();
  s4.querySelector('.sup-node').value = 4;
  s4.querySelector('.sup-kx').value   = 0;
  s4.querySelector('.sup-ky').value   = 1;
  s4.querySelector('.sup-kr').value   = 0;

  supportsTbody.appendChild(s1);
  supportsTbody.appendChild(s3);
  supportsTbody.appendChild(s4);

  // Carga nodal en Y: 1 2   -2.47
  const f1 = createFyRow();
  f1.querySelector('.fy-node').value = 2;
  f1.querySelector('.fy-val').value  = -2.47;
  fyTbody.appendChild(f1);
}

/* --------- GENERACIÓN DEL TXT --------- */

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

  let jbw;
  if (jbwInput) {
    jbw = parseInt(jbwInput, 10);
  } else {
    jbw = 3 + 3 * maxSpan;
  }

  const nspd = 0;
  const nca1 = 0;
  const nca3 = 0;

  const lines = [];

  // Línea 1: número de casos
  lines.push(' 1');

  // Línea 2: descripción
  lines.push(desc);

  // Línea 3: global
  const elaStr = noLeadingZeroDecimal(ela, 1); // 519120.0
  lines.push(
    `  ${nm}  ${nn}  ${na}  ${nspd}  ${jbw}  ${nca1}  ${nca2}  ${nca3}  ${elaStr}`
  );

    // Líneas de elementos (alineadas igual que el caso que funciona)
  elements.forEach(el => {
    const Istr  = noLeadingZeroDecimal(el.I, 4);     // => ".0241"
    const Astr  = Number(el.A).toFixed(2);           // => "1.66"
    const Lstr  = Number(el.L).toFixed(2);           // => "5.00", "10.00"
    const hasDistLoad = Math.abs(el.pa) > 1e-9 || Math.abs(el.pb) > 1e-9;

    // Parte base como en las líneas sin carga:
    // "  3  3  4   .0241  1.66  10.0 "
    let base = `  ${el.mem}  ${el.ni}  ${el.nj}   ${Istr}  ${Astr}  ${Lstr} `;

    if (!hasDistLoad) {
      // Si no hay carga distribuida, dejamos la línea corta
      lines.push(base);
    } else {
      // Queremos imitar EXACTAMENTE la posición de "-.25  -.25"
      // del archivo que sí funciona.

      // Formato tipo ".25" o "-.25" (sin cero antes del punto)
      const paStr = noLeadingZeroDecimal(el.pa, 2);
      const pbStr = noLeadingZeroDecimal(el.pb, 2);

      // Hacemos que la parte base llegue hasta la columna 49
      // (donde empieza el primer "-.25" en tu ejemplo bueno)
      const basePadded = base.padEnd(49, ' ');

      // Cada campo de carga ocupa 4 caracteres: "-.25"
      const paField = paStr.padStart(4, ' ');
      const pbField = pbStr.padStart(4, ' ');

      // Dos espacios entre pa y pb, y dos al final (igual que el ejemplo)
      const line = basePadded + paField + '  ' + pbField + '  ';
      lines.push(line);
    }
  });


  // Línea de apoyos (compacta)
  let supLine = ` ${na}`;
  supports.forEach(s => {
    supLine += ` ${s.node} ${s.kx} ${s.ky} ${s.kr}`;
  });
  lines.push(supLine);

  // Línea de cargas en Y (solo si hay)
  if (nca2 > 0) {
    let fyLine = ` ${nca2}`;
    loadsFy.forEach(L => {
      fyLine += ` ${L.node}   ${Number(L.val).toFixed(2)}`;
    });
    lines.push(fyLine);
  }

  return lines.join('\n');
}

/* --------- DESCARGAR --------- */

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
