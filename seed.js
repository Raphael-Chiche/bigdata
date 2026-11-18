const crypto = require("crypto");
const assert = require("assert");

const MAX = 50; 

const N = { users: 20, products: 5, orders: 25, promos: 10 };

let seed = Number(process.env.SEED || 42);
const rnd = () => { seed = (seed + 0x6D2B79F5) | 0; let t = Math.imul(seed ^ (seed >>> 15), 1 | seed); t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t; return ((t ^ (t >>> 14)) >>> 0) / 4294967296; };
const int = (a, b) => a + Math.floor(rnd() * (b - a + 1));
const pick = a => a[Math.floor(rnd() * a.length)];
const chance = p => rnd() < p;
const sample = (a, n) => { const c = [...a]; for (let i = c.length - 1; i > 0; i--) { const j = Math.floor(rnd() * (i + 1)); [c[i], c[j]] = [c[j], c[i]]; } return c.slice(0, n); };
const uuid = () => crypto.randomUUID();
const pad = (n, w) => String(n).padStart(w, "0");

const H = 36e5, DAY = 24 * H;
const NOW = Math.floor(Date.now() / 1000) * 1000;
const START = Date.UTC(2024, 0, 1);
const between = (a, b) => Math.floor((a + rnd() * (b - a)) / 1000) * 1000;
const d = ms => (ms == null ? null : new Date(ms));

const FIRST = ["Camille","Lucas","Léa","Hugo","Chloé","Louis","Emma","Nathan","Manon","Théo","Inès","Jules","Sarah","Adam","Zoé","Gabriel","Jade","Raphaël","Louise","Arthur","Alice","Paul","Lina","Tom","Rose","Noah","Anna","Ethan","Mila","Sacha"];
const LAST = ["Martin","Bernard","Dubois","Thomas","Robert","Richard","Petit","Durand","Leroy","Moreau","Simon","Laurent","Lefebvre","Michel","Garcia","David","Bertrand","Roux","Vincent","Fournier","Morel","Girard","André","Mercier","Dupont","Lambert","Bonnet","François","Martinez","Legrand"];
const STREETS = ["rue de la République","avenue Jean Jaurès","rue Victor Hugo","boulevard Gambetta","rue Pasteur","place de la Mairie","rue du Moulin","avenue de la Gare","rue des Écoles","quai des Brumes"];
const CITIES = [["Paris","75011","France","EUR"],["Lyon","69003","France","EUR"],["Marseille","13001","France","EUR"],["Toulouse","31000","France","EUR"],["Bordeaux","33000","France","EUR"],["Lille","59000","France","EUR"],["Nantes","44000","France","EUR"],["Rennes","35000","France","EUR"],["Bruxelles","1000","Belgique","EUR"],["London","SW1A 1AA","United Kingdom","GBP"]];
const CURRENCIES = { EUR: ["Euro (EUR)", 1], GBP: ["Livre sterling (GBP)", 0.85] };
const BRANDS = ["Nike","Adidas","Puma","Levi's","Lacoste","Le Coq Sportif","Petit Bateau","Armor-Lux","Veja","New Balance","Carhartt","Patagonia","The North Face","Kickers","Saint James","Converse","Vans","Asics","Eastpak","Aigle"];
const CATS = {
  "Vêtements": { "T-shirts": ["T-shirt","clothes",1500,4500], "Pulls": ["Pull","clothes",4000,12000], "Jeans": ["Jean","jeans",6000,13000], "Vestes": ["Veste","clothes",8000,30000] },
  "Chaussures": { "Baskets": ["Baskets","shoes",6000,18000], "Bottes": ["Bottes","shoes",9000,22000], "Sandales": ["Sandales","shoes",3000,8000] },
  "Accessoires": { "Sacs": ["Sac","none",2500,12000], "Casquettes": ["Casquette","none",1500,4000], "Écharpes": ["Écharpe","none",2000,6000] },
};
const SIZES = { clothes: ["XS","S","M","L","XL"], jeans: ["W30L32","W32L32","W34L32","W36L34"], shoes: ["38","39","40","41","42","43","44","45"], none: [null] };
const COLORS = ["Noir","Blanc","Bleu marine","Gris","Rouge","Vert","Beige","Marron"];
const ADJ = ["Essential","Héritage","Classic","Urban","Original","Premium","Vintage","Sport","Outdoor","Signature"];

function generate() {
  const T = {};
  const add = (t, row) => (T[t] ??= []).push(row);

  const cur = {};
  for (const [code, [name, rate]] of Object.entries(CURRENCIES)) { cur[code] = { id: uuid(), rate }; add("Currency", [cur[code].id, name]); }

  const brands = BRANDS.map(name => { const id = uuid(); add("Brand", [id, name]); return id; });

  const leaves = [], ancestors = {};
  for (const [root, subs] of Object.entries(CATS)) {
    const rid = uuid(); add("Category", [rid, root, null]);
    for (const [name, spec] of Object.entries(subs)) { const id = uuid(); add("Category", [id, name, rid]); leaves.push({ id, spec }); ancestors[id] = [id, rid]; }
  }
  const allCats = T.Category.map(r => r[0]);

  const products = [], variants = [];
  for (let i = 1; i <= N.products; i++) {
    const leaf = pick(leaves), [noun, sizeType, pmin, pmax] = leaf.spec;
    const p = { id: uuid(), launch: between(START, NOW - 30 * DAY), cats: [leaf.id] };
    if (chance(0.2)) { const other = pick(leaves).id; if (other !== leaf.id) p.cats.push(other); }
    add("Product", [p.id, "PRD-" + pad(i, 6), `${noun} ${pick(ADJ)} ${pick(BRANDS)}`.slice(0, 255), `${noun} ${pick(ADJ).toLowerCase()}, collection ${new Date(p.launch).getUTCFullYear()}.`, pick(brands)]);
    for (const c of p.cats) add("ProductCategory", [p.id, c]);
    p.catSet = new Set(p.cats.flatMap(c => ancestors[c]));

    let eur = Math.round(int(pmin, pmax) / 100) * 100 - 10;
    const hist = [{ at: p.launch, eur }];
    const changes = [...new Set(Array.from({ length: int(0, 1) }, () => between(p.launch + DAY, NOW)))].sort((a, b) => a - b);
    for (const at of changes) { eur = Math.max(990, Math.round(eur * (0.85 + rnd() * 0.3) / 10) * 10); hist.push({ at, eur }); }

    const sizes = SIZES[sizeType].length > 1 ? sample(SIZES[sizeType], int(2, SIZES[sizeType].length)) : SIZES[sizeType];
    for (const [color, size] of sample(sizes.flatMap(sz => COLORS.map(c => [c, sz])), int(1, 2))) {
      const v = { id: uuid(), product: p, prices: {} };
      add("Variant", [v.id, p.id, "VAR-" + pad(variants.length + 1, 7), size, color, chance(0.1) ? 0 : int(1, 150)]);
      for (const [code, c] of Object.entries(cur)) {
        v.prices[code] = hist.map(h => ({ at: h.at, value: Math.round(h.eur * c.rate) }));
        for (const h of v.prices[code]) add("Price", [uuid(), h.value, d(h.at), v.id, c.id]);
      }
      variants.push(v);
    }
    products.push(p);
  }
  const priceAt = (v, code, at) => v.prices[code].filter(h => h.at <= at).at(-1).value;
  const variantAvailableAt = at => { for (let k = 0; k < 20; k++) { const v = pick(variants); if (v.product.launch <= at) return v; } return null; };

  const users = [], defaults = [];
  const pwd = "scrypt$seed$" + crypto.scryptSync("password123", "seed", 32).toString("hex");
  for (let i = 1; i <= N.users; i++) {
    const first = pick(FIRST), last = pick(LAST);
    const created = between(START, NOW - DAY);
    const u = { id: uuid(), first, last, created, mail: `${first}.${last}${i}@example.com`.normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase().replace(/[^a-z0-9.@]/g, ""), phone: "+336" + pad(i, 8), addrs: [] };
    add("User", [u.id, first, u.mail, pwd, u.phone, d(created), chance(0.3) ? d(between(created, NOW)) : null, chance(0.92), null]);
    for (let k = int(1, 2); k > 0; k--) {
      const [city, zip, country, code] = k === 1 && chance(0.85) ? pick(CITIES.slice(0, 8)) : pick(CITIES);
      const a = { id: uuid(), street: `${int(1, 120)} ${pick(STREETS)}`, zip, city, country, code };
      add("Address", [a.id, u.id, a.street, zip, country, city]);
      u.addrs.push(a);
    }
    defaults.push([u.id, u.addrs[0].id]);
    users.push(u);
  }

  for (const u of users) {
    if (!chance(0.4)) continue;
    const id = uuid(), created = between(u.created, NOW);
    let last = created;
    const seen = new Set();
    for (let k = int(1, 2); k > 0; k--) {
      const v = variantAvailableAt(NOW);
      if (!v || seen.has(v.id)) continue;
      seen.add(v.id);
      const at = between(created, NOW); last = Math.max(last, at);
      add("CartItem", [id, v.id, int(1, 3), d(at)]);
    }
    T.Cart ??= []; T.Cart.push([id, u.id, d(created), seen.size ? d(last) : null]);
  }

  const promos = [];
  for (let i = 1; i <= N.promos; i++) {
    const scope = pick(["order", "order", "product", "category"]);
    const fixed = chance(0.3);
    const owner = chance(0.1) ? pick(users) : null;
    const start = owner ? between(owner.created, NOW) : between(START, NOW + 30 * DAY);
    const p = { id: uuid(), scope, start, end: chance(0.15) ? null : start + int(3, 60) * DAY, max: owner ? 1 : chance(0.3) ? int(20, 300) : null,
      owner: owner?.id ?? null, limited: owner ? true : chance(0.5), cur: fixed ? "EUR" : null, used: 0, usedBy: new Set(), products: new Set(), cats: new Set() };
    add("promotion", [p.id, owner ? `Offre personnelle ${owner.first}` : `Promo ${i} ${scope}`, scope, fixed ? int(5, 30) * 100 : int(5, 40),
      d(start), d(p.end), p.max, chance(0.8) ? "CODE" + pad(i, 4) : null, p.owner, p.limited, fixed ? cur.EUR.id : null, fixed ? "fixed" : "percent"]);
    if (scope === "product") for (const pr of sample(products, int(1, 3))) { p.products.add(pr.id); add("promotion_target", [uuid(), p.id, pr.id, null]); }
    if (scope === "category") for (const c of sample(allCats, int(1, 2))) { p.cats.add(c); add("promotion_target", [uuid(), p.id, null, c]); }
    promos.push(p);
  }
  const eligible = (p, at, uid, code, items) =>
    p.start <= at && (p.end == null || at <= p.end) && (p.owner == null || p.owner === uid) && (p.cur == null || p.cur === code) &&
    (p.max == null || p.used < p.max) && (!p.limited || (uid && !p.usedBy.has(uid))) &&
    (p.scope === "order" || items.some(v => p.products.has(v.product.id) || [...p.cats].some(c => v.product.catSet.has(c))));

  const orders = [];
  for (let i = 0; i < N.orders; i++) {
    const u = chance(0.9) ? pick(users) : null;
    const at = between(u ? u.created : START, NOW);
    const a = u ? pick(u.addrs) : (([city, zip, country, code]) => ({ street: `${int(1, 120)} ${pick(STREETS)}`, zip, city, country, code }))(pick(CITIES));
    const name = u ? [u.first, u.last] : [pick(FIRST), pick(LAST)];
    const items = [];
    for (let k = int(1, 2); k > 0; k--) { const v = variantAvailableAt(at); if (v && !items.includes(v)) items.push(v); }
    if (!items.length) continue;

    let promo = null;
    if (chance(0.3)) {
      const c = promos.filter(p => eligible(p, at, u?.id, a.code, items));
      if (c.length) { promo = pick(c); promo.used++; if (u) promo.usedBy.add(u.id); }
    }
    const age = NOW - at;
    const [status, upd] =
      age < DAY ? (chance(0.5) ? ["pending", null] : ["paid", at + int(1, 30) * 60e3]) :
      chance(0.07) ? ["cancelled", at + int(1, 24) * H] :
      age < 3 * DAY ? ["paid", at + int(1, 30) * 60e3] :
      age < 7 * DAY ? ["shipped", at + int(24, 48) * H] :
      ["delivered", at + int(2, 6) * DAY];
    orders.push({ id: uuid(), at, row: [u?.id ?? null, cur[a.code].id, d(at), d(upd == null ? null : Math.min(upd, NOW)), status,
      name.join(" "), u ? u.mail : `${name.join(".")}${i}@guest.example.com`.normalize("NFD").replace(/[^\x00-\x7f]/g, "").toLowerCase(),
      u ? u.phone : "+337" + pad(i, 8), a.street, a.zip, a.city, a.country, promo?.id ?? null],
      items: items.map(v => [v.id, int(1, 3), priceAt(v, a.code, at)]) });
  }
  orders.sort((x, y) => x.at - y.at);
  const seq = {};
  for (const o of orders) {
    const y = new Date(o.at).getUTCFullYear(); seq[y] = (seq[y] ?? 0) + 1;
    add("Orders", [o.id, `CMD-${y}-${pad(seq[y], 6)}`, ...o.row]);
    for (const it of o.items) add("OrderItem", [o.id, ...it]);
  }
  for (const [t, rows] of Object.entries(T)) assert(rows.length <= MAX, `${t} : ${rows.length} lignes > ${MAX}`);
  return { T, defaults };
}

const COLS = {
  Currency: ["id","name"], Brand: ["id","name"], Category: ["id","name","parent_id"],
  Product: ["id","ref_commercial","name","description","brand_id"], ProductCategory: ["id_product","id_category"],
  Variant: ["id","product_id","ref_commercial","size","color","stock"], Price: ["id","value","valid_date","variant_id","currency_id"],
  User: ["id","first_name","mail","password","phone_number","created_at","updated_at","isActive","defaultAddress"],
  Address: ["id","user_id","street_name","zip_code","country","city"],
  Cart: ["id","user_id","created_at","updated_at"], CartItem: ["cart_id","variant_id","quantity","updated_at"],
  promotion: ["id","name","scope","value","start_at","end_at","max_usage","code","user_id","limited_by_user","currency_id","discount_type"],
  promotion_target: ["id","promotion_id","product_id","category_id"],
  Orders: ["id","public_id","user_id","currency_id","created_at","updated_at","status","name","mail","phone_number","street_name","zip_code","city","country","promotion_id"],
  OrderItem: ["order_id","variant_id","quantity","unit_price"],
};

async function insert(c, table, rows) {
  const cols = COLS[table], per = Math.floor(30000 / cols.length);
  for (let i = 0; i < rows.length; i += per) {
    const chunk = rows.slice(i, i + per);
    const vals = chunk.map((r, j) => "(" + r.map((_, k) => "$" + (j * cols.length + k + 1)) + ")");
    await c.query(`insert into "${table}" (${cols.map(x => `"${x}"`)}) values ${vals}`, chunk.flat());
  }
}

const CHECKS = {
  "prix commande = prix en vigueur à la date": `select count(*) from "OrderItem" oi join "Orders" o on o.id=oi.order_id
    where oi.unit_price is distinct from (select p.value from "Price" p where p.variant_id=oi.variant_id and p.currency_id=o.currency_id and p.valid_date<=o.created_at order by p.valid_date desc limit 1)`,
  "commande avant création du compte": `select count(*) from "Orders" o join "User" u on u.id=o.user_id where o.created_at < u.created_at`,
  "updated_at < created_at": `select (select count(*) from "Orders" where updated_at < created_at) + (select count(*) from "User" where updated_at < created_at) + (select count(*) from "Cart" where updated_at < created_at)`,
  "promo hors période": `select count(*) from "Orders" o join promotion p on p.id=o.promotion_id where o.created_at < p.start_at or o.created_at > p.end_at`,
  "quota promo dépassé": `select count(*) from (select 1 from "Orders" o join promotion p on p.id=o.promotion_id where p.max_usage is not null group by p.id, p.max_usage having count(*) > p.max_usage) x`,
  "promo perso utilisée par un autre": `select count(*) from "Orders" o join promotion p on p.id=o.promotion_id where p.user_id is not null and o.user_id is distinct from p.user_id`,
  "adresse par défaut d'un autre client": `select count(*) from "User" u join "Address" a on a.id=u."defaultAddress" where a.user_id <> u.id`,
  "commande sans article": `select count(*) from "Orders" o where not exists (select 1 from "OrderItem" i where i.order_id=o.id)`,
  "commande pending avec updated_at": `select count(*) from "Orders" where status='pending' and updated_at is not null`,
};

const run = async (c) => {
  console.time("seed");
  const { T, defaults } = generate();
  await c.query("begin");
  try {
    await c.query(`truncate ${Object.keys(COLS).map(t => `"${t}"`)} cascade`);
    await insert(c, "Currency", T.Currency);
    for (const t of ["Brand","Category","Product","ProductCategory","Variant","Price","User","Address"]) await insert(c, t, T[t]);
    await c.query(`update "User" u set "defaultAddress"=x.a from unnest($1::uuid[], $2::uuid[]) x(u, a) where u.id=x.u`, [defaults.map(r => r[0]), defaults.map(r => r[1])]);
    for (const t of ["Cart","CartItem","promotion","promotion_target","Orders","OrderItem"]) await insert(c, t, T[t] ?? []);
    await c.query("commit");
  } catch (e) { await c.query("rollback"); throw e; }
  for (const t of Object.keys(COLS)) console.log(t.padEnd(18), (await c.query(`select count(*)::int n from "${t}"`)).rows[0].n);
  for (const [label, q] of Object.entries(CHECKS)) assert.strictEqual((await c.query(`select (${q})::int n`)).rows[0].n, 0, "contrôle échoué : " + label);
  console.log(`OK : ${Object.keys(CHECKS).length} contrôles d'intégrité passés`);
  console.timeEnd("seed");
};
module.exports = run;

if (require.main === module) (async () => {
  const { Client, defaults } = require("pg");
  defaults.parseInputDatesAsUTC = true;
  assert(process.env.DATABASE_URL, "DATABASE_URL manquant dans .env");
  const c = new Client({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
  await c.connect();
  try { await run(c); } finally { await c.end(); }
})().catch(e => { console.error(e.message); process.exit(1); });
