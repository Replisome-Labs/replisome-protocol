window.addEventListener("load", function () {
  const { metadata, metadataId, width, height, colors, data } = tokenData;

  document.title = `HiggsPixel - ${metadata}/${metadataId}`;

  const canvas = document.createElement("canvas");

  function render() {
    const dpr = window.devicePixelRatio;
    const pixelScale = Math.min(
      window.innerWidth / width,
      window.innerHeight / height
    ); // scale to fit
    setCanvasSize(canvas, width, height, pixelScale, dpr);
    draw(canvas, pixelScale, width, height, colors, data);
  }

  render();
  document.body.appendChild(canvas);

  window.addEventListener("resize", render);
  if (window.screen.orienration) {
    window.screen.orientation.addEventListner("change", render);
  }
});

function setCanvasSize(canvas, width, height, pixelScale, dpr) {
  canvas.width = width * pixelScale * dpr;
  canvas.height = height * pixelScale * dpr;
  canvas.style.width = `${width * pixelScale}px`;
  canvas.style.height = `${height * pixelScale}px`;
  const ctx = canvas.getContext("2d");
  ctx.scale(dpr, dpr);
}

function draw(canvas, pixelScale, width, height, colors, data) {
  const ctx = canvas.getContext("2d");
  ctx.clearRect(0, 0, width * pixelScale, height * pixelScale);

  const dataLength = hexDataLength(data);
  for (let i = 0; i < dataLength; i++) {
    const colorIndex = parseInt(hexDataSlice(data, i, i + 1), 16) - 1;
    if (colorIndex === -1) continue;

    const color = hexToRgba(colors[colorIndex]);
    const { x, y } = parsePosition(i, width);

    ctx.fillStyle = `rgba(${color.r}, ${color.g}, ${color.b}, ${color.a})`;
    ctx.fillRect(x * pixelScale, y * pixelScale, pixelScale, pixelScale);
  }
}

function parsePosition(i, w) {
  const x = Math.floor(i % w);
  const y = Math.floor(i / w);
  return { x, y };
}

function round(number, digits = 0, base = Math.pow(10, digits)) {
  return Math.round(base * number) / base;
}

function hexToRgba(hex) {
  if (hex[0] === "#") hex = hex.substring(1);
  return {
    r: parseInt(hex.substring(0, 2), 16),
    g: parseInt(hex.substring(2, 4), 16),
    b: parseInt(hex.substring(4, 6), 16),
    a: hex.length === 8 ? round(parseInt(hex.substring(6, 8), 16) / 255, 2) : 1,
  };
}

function hexDataLength(data) {
  return (data.length - 2) / 2;
}

function hexDataSlice(data, offset, endOffset) {
  offset = 2 + 2 * offset;
  if (endOffset != null) {
    return "0x" + data.substring(offset, 2 + 2 * endOffset);
  }
  return "0x" + data.substring(offset);
}
