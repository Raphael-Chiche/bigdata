// Usage: node --env-file=.env db.js migrate | seed | test
const { Client } = require("pg");
const fs = require("fs");
const assert = require("assert");

const TABLES = ["User","Address","Product","Category","ProductCategory","Brand","Variant","Price","Currency","Cart","CartItem","Orders","OrderItem","promotion","promotion_target"];

(async () => {
  assert(process.env.DATABASE_URL, "DATABASE_URL manquant dans .env");
  const c = new Client({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
  await c.connect();
  try {
    const cmd = process.argv[2];
    if (cmd === "migrate") {
      // multi-statement simple query = une seule transaction implicite : tout ou rien
      await c.query(fs.readFileSync(__dirname + "/schema.sql", "utf8"));
      console.log("schema.sql appliqué");
    } else if (cmd === "seed") {
      await require("./seed")(c);
    } else if (cmd === "test") {
      const { rows } = await c.query("select table_name from information_schema.tables where table_schema='public'");
      const have = rows.map(r => r.table_name);
      const missing = TABLES.filter(t => !have.includes(t));
      assert.deepStrictEqual(missing, [], "tables manquantes: " + missing);
      // insert + rollback : vérifie contraintes/FK sans laisser de données
      await c.query("begin");
      const b = await c.query(`insert into "Brand"(id,name) values (gen_random_uuid(),'test') returning id`);
      await c.query(`insert into "Product"(id,ref_commercial,name,description,brand_id) values (gen_random_uuid(),'T1','p','d',$1)`, [b.rows[0].id]);
      await c.query("rollback");
      console.log("OK: 15 tables présentes, insert Brand+Product fonctionne (rollback)");
    } else throw new Error("commande: migrate | seed | test");
  } finally { await c.end(); }
})().catch(e => { console.error(e.message); process.exit(1); });
