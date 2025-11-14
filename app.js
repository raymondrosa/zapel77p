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

function setup() {
  const elementsTbody = document.querySelector('#elements-table tbody');
  const supportsTbody = document.querySelector('#supports-table tbody');
  const fyTbody = document.querySelector('#fy-table tbody');
  const preview = document.querySelector('#preview');

  // Añadir elemento
  document.querySelector('#btn-add-element').addEventListener('click', () => {
    const index = elementsTbody.querySelectorAll('tr').length + 1;
    elementsTbody.appendChild(createElementRow(index));
  });

  // Añadir soporte
  document.querySelector('#btn-add-support').addEventListener('click', () => {
    supportsTbody.appendChild(createSupportRow());
  });

  // Añadir carga en Y
  document.querySelector('#btn-add-fy').addEventListener('click', () => {
    fyTbody.appendChild(createFyRow());
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
      }
    }
  });

  // Generar archivo
  document.querySelector('#btn-generate').addEventListener('click', () => {
    const txt = generateTxt();
    preview.textContent = txt;
    const filename = document.querySelector('#filename').value || 'acera.txt';
    downloadFile(filename, txt);
  });
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
    loadsFy.push({ node, val });
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
// Línea 1: número de casos (para ZAPEL77P)
lines.push('1');
// Línea 2: descripción
lines.push(desc);
// Línea 3: global
lines.push(
  `${nm}  ${nn}  ${na}  ${nspd}  ${jbw}  ${nca1}  ${nca2}  ${nca3}  ${Number(ela).toFixed(1)}`
);
  // Líneas de elementos, todos reales con decimales fijos
  elements.forEach(el => {
    const line =
      `${el.mem}  ${el.ni}  ${el.nj}` +
      `   ${Number(el.I).toFixed(4)}` +
      `  ${Number(el.A).toFixed(2)}` +
      `  ${Number(el.L).toFixed(2)}` +
      `  ${Number(el.pa).toFixed(2)}` +
      `  ${Number(el.pb).toFixed(2)}`;
    lines.push(line);
  });

  // Línea de apoyos
  let supLine = `${na}`;
  supports.forEach(s => {
    supLine += ` ${s.node} ${s.kx} ${s.ky} ${s.kr}`;
  });
  lines.push(supLine);

  // Línea de cargas en Y
  if (nca2 > 0) {
    let fyLine = `${nca2}`;
    loadsFy.forEach(L => {
      fyLine += ` ${L.node} ${Number(L.val).toFixed(2)}`;
    });
    lines.push(fyLine);
  }

  // Saltos de línea reales
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
