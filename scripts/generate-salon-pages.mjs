import fs from 'node:fs';
import path from 'node:path';

const ROOT = process.cwd();
const SITE = 'https://moz-saloes.github.io/MOZ-SALOES/';
const OUTPUT = path.join(ROOT, 'saloes');
const PAGE_SIZE = 1000;

function readConfig() {
  const html = fs.readFileSync(path.join(ROOT, 'index.html'), 'utf8');
  const url = html.match(/const SUPABASE_URL='([^']+)'/);
  const key = html.match(/const SUPABASE_PUBLISHABLE_KEY='([^']+)'/);
  if (!url || !key) throw new Error('Não foi possível identificar a configuração pública do Supabase no index.html.');
  if (!/^https:\/\/[a-z0-9-]+\.supabase\.co$/i.test(url[1])) throw new Error('URL Supabase inesperado.');
  if (!key[1].startsWith('sb_publishable_')) throw new Error('A chave configurada não é uma chave publishable.');
  return { url: url[1], key: key[1] };
}

async function fetchRows(config, table, select, filters = []) {
  const all = [];
  for (let offset = 0; offset < 100000; offset += PAGE_SIZE) {
    const url = new URL(config.url + '/rest/v1/' + table);
    url.searchParams.set('select', select);
    for (const [name, value] of filters) url.searchParams.set(name, value);
    const response = await fetch(url, {
      headers: {
        apikey: config.key,
        Authorization: 'Bearer ' + config.key,
        Range: offset + '-' + (offset + PAGE_SIZE - 1),
        'Range-Unit': 'items'
      },
      signal: AbortSignal.timeout(30000)
    });
    if (!response.ok) {
      const body = await response.text();
      throw new Error('Supabase ' + table + ' respondeu ' + response.status + ': ' + body.slice(0, 500));
    }
    const rows = await response.json();
    if (!Array.isArray(rows)) throw new Error('Resposta inesperada ao consultar ' + table + '.');
    all.push(...rows);
    if (rows.length < PAGE_SIZE) return all;
  }
  throw new Error('A consulta de ' + table + ' excedeu o limite de segurança de paginação.');
}

function esc(value) {
  return String(value ?? '').replace(/[&<>"']/g, c => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'
  })[c]);
}
function cleanText(value) {
  return String(value ?? '').replace(/\s+/g, ' ').trim();
}
function slugify(value) {
  return cleanText(value).normalize('NFD').replace(/[\u0300-\u036f]/g, '')
    .toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '').slice(0, 70) || 'salao';
}
function pagePath(salon) {
  return 'saloes/' + slugify(salon.name) + '-' + String(salon.id) + '/';
}
function publicImage(config, imagePath) {
  const value = String(imagePath ?? '').trim();
  if (!value) return '';
  if (/^https?:\/\//i.test(value)) return value;
  return config.url + '/storage/v1/object/public/salon-images/' +
    value.split('/').map(encodeURIComponent).join('/');
}
function whatsappNumber(value) {
  let digits = String(value ?? '').replace(/\D/g, '');
  if (digits.startsWith('00')) digits = digits.slice(2);
  if (digits.startsWith('258')) digits = digits.slice(3);
  if (digits.length === 10 && digits.startsWith('0')) digits = digits.slice(1);
  if (digits.length === 9 && digits.startsWith('8')) digits = '258' + digits;
  return /^2588\d{8}$/.test(digits) ? digits : '';
}
function locationText(s) {
  return [s.neighborhood, s.city, s.municipality, s.district, s.province, 'Moçambique']
    .filter(Boolean).map(cleanText).filter((v, i, a) => a.indexOf(v) === i).join(', ');
}
function money(value) {
  const n = Number(value);
  return Number.isFinite(n) ? n.toLocaleString('pt-MZ') + ' MT' : 'Preço sob consulta';
}
function jsonForHtml(value) {
  return JSON.stringify(value).replace(/</g, '\\u003c').replace(/>/g, '\\u003e').replace(/&/g, '\\u0026');
}

function renderPage(config, salon, services, images) {
  const title = cleanText(salon.name) + ' | Serviços, preços e contactos em ' +
    [salon.district, salon.province].filter(Boolean).join(', ');
  const description = cleanText(salon.description) ||
    (salon.provider_type === 'independent'
      ? 'Consulta os serviços e contactos deste profissional de beleza em Moçambique.'
      : 'Consulta os serviços, preços, fotografias e contactos deste salão em Moçambique.');
  const canonical = SITE + pagePath(salon);
  const photos = images.map(row => ({
    url: publicImage(config, row.image_path),
    caption: cleanText(row.caption) || 'Fotografia de trabalhos de ' + salon.name
  })).filter(row => row.url);
  const phone = whatsappNumber(salon.whatsapp) || whatsappNumber(salon.phone);
  const place = locationText(salon);
  const serviceRows = services.map(service =>
    '<li><span>' + esc(service.name) + '</span><strong>' +
    esc(service.price_mzn === null ? 'Preço sob consulta' : money(service.price_mzn)) + '</strong></li>'
  ).join('');
  const gallery = photos.length
    ? '<section class="gallery" aria-label="Fotografias"><h2>Fotografias</h2><div class="photos">' +
      photos.map(photo => '<figure><img src="' + esc(photo.url) + '" alt="' + esc(photo.caption) +
        '" loading="lazy"><figcaption>' + esc(photo.caption) + '</figcaption></figure>').join('') +
      '</div></section>'
    : '';
  const serviceMode = salon.provider_type === 'independent'
    ? ({ at_location: 'Atendimento no próprio local', home: 'Atendimento ao domicílio', both: 'Atendimento no local e ao domicílio' }[salon.service_mode] || 'Atendimento por marcação')
    : 'Estabelecimento de beleza';
  const serviceArea = salon.provider_type === 'independent'
    ? [salon.service_address, salon.service_areas].filter(Boolean).join(' · ')
    : [salon.address, salon.neighborhood, salon.district, salon.province].filter(Boolean).join(', ');
  const mapQuery = [salon.service_address || salon.address, salon.neighborhood, salon.city, salon.district, salon.province, 'Moçambique'].filter(Boolean).join(', ');
  const mapLink = mapQuery
    ? '<a class="secondary" href="https://www.google.com/maps/search/?api=1&query=' + encodeURIComponent(mapQuery) +
      '" target="_blank" rel="noopener noreferrer">Ver localização</a>' : '';
  const whatsappLink = phone
    ? '<a class="primary" href="https://wa.me/' + phone + '" target="_blank" rel="noopener noreferrer">Contactar pelo WhatsApp</a>' : '';
  const appLink = SITE + '?salao=' + encodeURIComponent(salon.id);
  const schema = {
    '@context': 'https://schema.org',
    '@type': salon.provider_type === 'independent' ? 'ProfessionalService' : 'BeautySalon',
    name: cleanText(salon.name),
    url: canonical,
    description,
    image: photos.map(p => p.url),
    telephone: salon.phone || undefined,
    address: {
      '@type': 'PostalAddress',
      streetAddress: salon.address || salon.service_address || undefined,
      addressLocality: [salon.neighborhood, salon.city, salon.district].filter(Boolean).join(', ') || undefined,
      addressRegion: salon.province || undefined,
      addressCountry: 'MZ'
    },
    areaServed: salon.service_areas || 'Moçambique',
    hasOfferCatalog: {
      '@type': 'OfferCatalog',
      name: 'Serviços de ' + cleanText(salon.name),
      itemListElement: services.map(service => ({
        '@type': 'Offer',
        itemOffered: { '@type': 'Service', name: cleanText(service.name) },
        price: service.price_mzn === null ? undefined : Number(service.price_mzn),
        priceCurrency: 'MZN'
      }))
    }
  };
  if (salon.latitude !== null && salon.latitude !== undefined &&
      salon.longitude !== null && salon.longitude !== undefined &&
      Number.isFinite(Number(salon.latitude)) && Number.isFinite(Number(salon.longitude))) {
    schema.geo = { '@type': 'GeoCoordinates', latitude: Number(salon.latitude), longitude: Number(salon.longitude) };
  }
  for (const key of Object.keys(schema)) if (schema[key] === undefined) delete schema[key];

  return '<!doctype html>\n<html lang="pt-MZ">\n<head>\n' +
    '<meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">\n' +
    '<title>' + esc(title) + '</title>\n' +
    '<meta name="description" content="' + esc(description.slice(0, 300)) + '">\n' +
    '<meta name="robots" content="index,follow,max-image-preview:large">\n' +
    '<link rel="canonical" href="' + esc(canonical) + '">\n' +
    '<meta property="og:type" content="website"><meta property="og:locale" content="pt_MZ">\n' +
    '<meta property="og:site_name" content="MOZ SALÕES"><meta property="og:title" content="' + esc(title) + '">\n' +
    '<meta property="og:description" content="' + esc(description.slice(0, 300)) + '"><meta property="og:url" content="' + esc(canonical) + '">\n' +
    (photos[0] ? '<meta property="og:image" content="' + esc(photos[0].url) + '">\n' : '') +
    '<meta name="twitter:card" content="' + (photos[0] ? 'summary_large_image' : 'summary') + '">\n' +
    '<link rel="icon" type="image/svg+xml" href="../../favicon.svg">\n' +
    '<script type="application/ld+json">' + jsonForHtml(schema) + '</' + 'script>\n' +
    '<style> *{box-sizing:border-box}body{margin:0;background:#f4f7fb;color:#18243a;font:16px/1.6 system-ui,-apple-system,Segoe UI,sans-serif}header{background:#102b63;color:white;padding:18px max(20px,calc((100% - 980px)/2));display:flex;align-items:center;justify-content:space-between;gap:12px}header a{color:white;text-decoration:none;font-weight:750}.brand{font-weight:900;letter-spacing:.04em}main{max-width:980px;margin:28px auto;padding:0 18px}.panel{background:white;border:1px solid #e2e8f0;border-radius:18px;padding:clamp(20px,4vw,36px);box-shadow:0 8px 30px #102b630b}.eyebrow{color:#1759a6;font-weight:800;text-transform:uppercase;font-size:.78rem;letter-spacing:.08em}h1{font-size:clamp(2rem,5vw,3rem);line-height:1.12;margin:.4em 0}h2{font-size:1.25rem;margin:28px 0 12px}.place,.muted{color:#5b687d}.chips{display:flex;flex-wrap:wrap;gap:8px;margin:14px 0}.chip{background:#eef4fc;border-radius:999px;padding:6px 12px;font-size:.9rem}.actions{display:flex;flex-wrap:wrap;gap:10px;margin-top:22px}.primary,.secondary{display:inline-flex;padding:11px 16px;border-radius:10px;text-decoration:none;font-weight:750}.primary{background:#1558a6;color:#fff}.secondary{border:1px solid #cbd5e1;color:#17345f;background:#fff}.services{list-style:none;padding:0;margin:0;border-top:1px solid #e7edf5}.services li{display:flex;justify-content:space-between;gap:18px;padding:12px 2px;border-bottom:1px solid #e7edf5}.services strong{white-space:nowrap}.photos{display:grid;grid-template-columns:repeat(auto-fit,minmax(190px,1fr));gap:14px}.photos figure{margin:0;background:#f8fafc;border-radius:12px;overflow:hidden}.photos img{display:block;width:100%;height:230px;object-fit:cover}.photos figcaption{padding:9px 11px;color:#5b687d;font-size:.9rem}footer{text-align:center;color:#66758c;padding:28px 18px;font-size:.9rem}a:focus-visible{outline:3px solid #eab308;outline-offset:3px}@media(max-width:560px){header{align-items:flex-start;flex-direction:column}.services li{align-items:flex-start;flex-direction:column;gap:2px}.photos img{height:210px}}</style>\n' +
    '</head>\n<body>\n<header><a class="brand" href="' + SITE + '">MOZ SALÕES 🇲🇿</a><a href="' + SITE + '">Explorar directório</a></header>\n<main><article class="panel"><div class="eyebrow">' + esc(salon.provider_type === 'independent' ? 'Profissional independente' : 'Salão de beleza') + '</div>\n<h1>' + esc(salon.name) + '</h1><p class="place">' + esc(place) + '</p>\n<p>' + esc(description) + '</p><div class="chips"><span class="chip">' + esc(serviceMode) + '</span>' +
    (salon.experience_years !== null && salon.experience_years !== undefined ? '<span class="chip">' + esc(salon.experience_years) + ' anos de experiência</span>' : '') +
    '</div>' + (serviceArea ? '<p class="muted">' + esc(serviceArea) + '</p>' : '') +
    '<div class="actions">' + whatsappLink + mapLink + '<a class="secondary" href="' + esc(appLink) + '">Ver perfil e marcar atendimento</a></div>' +
    '<section><h2>Serviços e preços</h2>' +
    (serviceRows ? '<ul class="services">' + serviceRows + '</ul>' : '<p class="muted">Este perfil ainda não tem serviços publicados.</p>') +
    '</section>' + gallery + '</article></main>\n<footer>Perfil público no MOZ SALÕES · Directório digital de beleza de Moçambique</footer>\n</body>\n</html>\n';
}

function renderSitemap(urls, lastmod) {
  const entries = [
    '<url><loc>' + SITE + '</loc><lastmod>' + lastmod + '</lastmod><changefreq>daily</changefreq><priority>1.0</priority></url>',
    ...urls.map(url => '<url><loc>' + esc(url) + '</loc><lastmod>' + lastmod + '</lastmod><changefreq>weekly</changefreq><priority>0.8</priority></url>')
  ];
  return '<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n' +
    entries.map(entry => '  ' + entry).join('\n') + '\n</urlset>\n';
}

async function main() {
  const config = readConfig();
  const [salons, services, images] = await Promise.all([
    fetchRows(config, 'salons', 'id,name,description,phone,whatsapp,province,district,municipality,city,neighborhood,address,latitude,longitude,status,provider_type,service_mode,service_address,service_areas,experience_years,specialties,languages', [['status', 'eq.active'], ['order', 'name.asc']]),
    fetchRows(config, 'services', 'id,salon_id,name,price_mzn,active', [['active', 'eq.true'], ['order', 'name.asc']]),
    fetchRows(config, 'salon_images', 'salon_id,image_path,caption,sort_order', [['order', 'sort_order.asc']])
  ]);
  if (!salons.length) console.log('Nenhum perfil activo foi encontrado; será publicado apenas o directório.');
  fs.rmSync(OUTPUT, { recursive: true, force: true });
  fs.mkdirSync(OUTPUT, { recursive: true });
  const serviceMap = new Map();
  for (const row of services) {
    if (!serviceMap.has(row.salon_id)) serviceMap.set(row.salon_id, []);
    serviceMap.get(row.salon_id).push(row);
  }
  const imageMap = new Map();
  for (const row of images) {
    if (!imageMap.has(row.salon_id)) imageMap.set(row.salon_id, []);
    imageMap.get(row.salon_id).push(row);
  }
  const urls = [];
  for (const salon of salons) {
    if (!salon.id || !salon.name) continue;
    const relative = pagePath(salon);
    const directory = path.join(ROOT, relative);
    fs.mkdirSync(directory, { recursive: true });
    const html = renderPage(config, salon, serviceMap.get(salon.id) || [], imageMap.get(salon.id) || []);
    fs.writeFileSync(path.join(directory, 'index.html'), html, 'utf8');
    urls.push(SITE + relative);
  }
  const date = new Date().toISOString().slice(0, 10);
  fs.writeFileSync(path.join(ROOT, 'sitemap.xml'), renderSitemap(urls, date), 'utf8');
  fs.writeFileSync(path.join(OUTPUT, 'index.html'),
    '<!doctype html><html lang="pt-MZ"><head><meta charset="utf-8"><meta name="robots" content="noindex,follow"><meta http-equiv="refresh" content="0;url=../"></head><body><p><a href="../">Voltar ao MOZ SALÕES</a></p></body></html>\n', 'utf8');
  console.log('Páginas públicas geradas: ' + urls.length);
  console.log('Sitemap actualizado com ' + (urls.length + 1) + ' URLs.');
}

main().catch(error => {
  console.error(error);
  process.exitCode = 1;
});
