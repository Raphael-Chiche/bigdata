-- Défi 1
--  Quel est le montant moyen d'une commande validée dans chaque pays de livraison ? Comparez le nombre de commandes et le chiffre d'affaires.
SELECT o.country, c.name AS currency,
  COUNT(DISTINCT o.id) AS nb_commandes,
  ROUND(SUM(oi.quantity * oi.unit_price) / 100.0, 2) AS CA
FROM "Orders" o
JOIN "OrderItem" oi ON oi.order_id = o.id
JOIN "Currency" c ON c.id = o.currency_id
WHERE o.status IN ('paid', 'shipped', 'delivered')
GROUP BY o.country, c.name
ORDER BY CA;

-- Défi 2
-- Quelles sont les 20 villes au panier moyen le plus élevé, parmi celles ayant au moins 30 commandes ?

SELECT o.city,
       ROUND(SUM(oi.quantity * oi.unit_price) / 100.0 / COUNT(DISTINCT o.id), 2) AS panier_moyen
FROM "Orders" o
JOIN "OrderItem" oi ON oi.order_id = o.id
JOIN "Currency" cur ON cur.id = o.currency_id
WHERE o.status IN ('paid', 'shipped', 'delivered')
GROUP BY o.city , cur.name
HAVING COUNT(DISTINCT o.id) >= 30
ORDER BY panier_moyen DESC
LIMIT 20


-- Défi 3 
-- Quels sont les 50 clients avec le plus de commandes payées sur 12 mois ? Affichez aussi leur dépense totale

SELECT u.first_name,
       COUNT(DISTINCT o.id) AS nb_commandes,
       ROUND(SUM(oi.quantity * oi.unit_price) / 100.0, 2) AS total
FROM "Orders" o
JOIN "OrderItem" oi ON oi.order_id = o.id
JOIN "Currency" cur ON cur.id = o.currency_id
JOIN "User" u ON u.id = o.user_id
WHERE o.status IN ('paid', 'shipped', 'delivered')
  AND o.created_at >= NOW() - INTERVAL '12 months'
GROUP BY u.id, u.first_name, cur.name
ORDER BY nb_commandes DESC, total DESC
LIMIT 50;

-- Défi 4
-- Quelles variantes actives du catalogues n'ont jamais été achetées ?

SELECT v.ref_commercial as reference, v.size, v.color, v.stock
FROM "Variant" v
WHERE v.stock > 0
  AND NOT EXISTS (
    SELECT 1
    FROM "OrderItem" oi
    JOIN "Orders" o ON o.id = oi.order_id
    WHERE oi.variant_id = v.id
      AND o.status IN ('paid', 'shipped', 'delivered')
  );

-- Défi 5
-- Classez les marque par chiffre d'affaires en teannt compte des quantités et des prix réellement payés.

SELECT RANK() OVER (PARTITION BY currency ORDER BY SUM(net) DESC) AS rang,
       brand AS name, ROUND(SUM(net) / 100.0, 2) AS chiffre_daffaire, currency
FROM (
  SELECT cur.name AS currency, b.id AS bid, b.name AS brand,
         oi.quantity * oi.unit_price * (1 - CASE
           WHEN NOT e.elig THEN 0
           WHEN pr.discount_type = 'percent' THEN pr.value / 100.0
           ELSE LEAST(pr.value, SUM(CASE WHEN e.elig THEN oi.quantity * oi.unit_price END) OVER w)
                / SUM(CASE WHEN e.elig THEN oi.quantity * oi.unit_price END) OVER w END) AS net
  FROM "Orders" o
  JOIN "OrderItem" oi ON oi.order_id = o.id
  JOIN "Variant" v ON v.id = oi.variant_id
  JOIN "Product" p ON p.id = v.product_id
  JOIN "Brand" b ON b.id = p.brand_id
  JOIN "Currency" cur ON cur.id = o.currency_id
  LEFT JOIN "promotion" pr ON pr.id = o.promotion_id
  CROSS JOIN LATERAL (SELECT COALESCE(pr.scope = 'order' OR EXISTS (
      SELECT 1 FROM "promotion_target" pt
      WHERE pt.promotion_id = pr.id
        AND (pt.product_id = p.id OR EXISTS (
          SELECT 1 FROM "ProductCategory" pc JOIN "Category" c ON c.id = pc.id_category
          WHERE pc.id_product = p.id AND pt.category_id IN (c.id, c.parent_id)))), FALSE) AS elig) e
  WHERE o.status IN ('paid', 'shipped', 'delivered')
  WINDOW w AS (PARTITION BY o.id)
) n
GROUP BY bid, brand, currency
ORDER BY currency, chiffre_daffaire DESC;

-- Défi 7
-- Quels clients ayant déjà acheté n'ont rien commandé depuis 180 jours ?

SELECT 
  u.first_name,
  u.mail,
  MAX(o.created_at) AS derniere_commande,
  COUNT(*) FILTER (WHERE o.status IN ('paid', 'shipped', 'delivered')) AS nb_achats
FROM "User" u
JOIN "Orders" o ON o.user_id = u.id
GROUP BY u.first_name, u.mail
HAVING COUNT(*) FILTER (WHERE o.status IN ('paid', 'shipped', 'delivered')) > 0
   AND MAX(o.created_at) < NOW() - INTERVAL '180 days'
ORDER BY derniere_commande;

-- Défi 8
-- Quelle catégorie réalise le plus de ventes dans chaque pays ? Un produit peut appartenir à plusieurs catégories"

SELECT country, currency, category, ROUND(ca / 100.0, 2) AS chiffre_daffaire
FROM (
  SELECT o.country, cur.name AS currency, c.name AS category,
         SUM(oi.quantity * oi.unit_price) AS ca,
         RANK() OVER (PARTITION BY o.country, cur.name ORDER BY SUM(oi.quantity * oi.unit_price) DESC) AS rang
  FROM "Orders" o
  JOIN "OrderItem" oi ON oi.order_id = o.id
  JOIN "Variant" v ON v.id = oi.variant_id
  JOIN (
    SELECT pc.id_product, c.id AS category_id FROM "ProductCategory" pc JOIN "Category" c ON c.id = pc.id_category
    UNION 
    SELECT pc.id_product, c.parent_id FROM "ProductCategory" pc JOIN "Category" c ON c.id = pc.id_category
    WHERE c.parent_id IS NOT NULL
  ) pcat ON pcat.id_product = v.product_id
  JOIN "Category" c ON c.id = pcat.category_id
  JOIN "Currency" cur ON cur.id = o.currency_id
  WHERE o.status IN ('paid', 'shipped', 'delivered')
  GROUP BY o.country, cur.name, c.id, c.name
) t
WHERE rang = 1
ORDER BY country, currency;


-- Défi 18 
-- Quelle est la variation en euros et en pourcentage du CA par pays par rapport au mois précédent, y compris les mois à zéro ?

SELECT country, to_char(mois, 'YYYY-MM') AS mois,
       ROUND(ca / 100.0, 2) AS ca,
       ROUND((ca - ca_prec) / 100.0, 2) AS variation,
       ROUND(100.0 * (ca - ca_prec) / NULLIF(ca_prec, 0), 2) AS variation_pct
FROM (
  SELECT p.country, m.mois,
         COALESCE(SUM(oi.quantity * oi.unit_price) FILTER (WHERE o.created_at >= m.mois), 0) AS ca,
         COALESCE(SUM(oi.quantity * oi.unit_price) FILTER (WHERE o.created_at < m.mois), 0) AS ca_prec
  FROM generate_series((SELECT date_trunc('month', MIN(created_at)) FROM "Orders"),
                       (SELECT date_trunc('month', MAX(created_at)) FROM "Orders"),
                       INTERVAL '1 month') AS m(mois)
  CROSS JOIN (SELECT DISTINCT country FROM "Orders") p
  LEFT JOIN "Orders" o ON o.country = p.country
                      AND o.status IN ('paid', 'shipped', 'delivered')
                      AND o.created_at >= m.mois - INTERVAL '1 month'
                      AND o.created_at <  m.mois + INTERVAL '1 month'
  LEFT JOIN "OrderItem" oi ON oi.order_id = o.id
  GROUP BY p.country, m.mois
) t
ORDER BY country, mois; 

-- Défi 19
-- Quelle proportion des clients repasse commande dans les 30, 60 et 90 jours après leur premier achat ?

SELECT COUNT(DISTINCT o1.user_id) AS nb_clients,
       ROUND(100.0 * COUNT(DISTINCT o1.user_id) FILTER (WHERE o2.created_at <= o1.created_at + INTERVAL '30 days')
             / COUNT(DISTINCT o1.user_id), 2) AS pct_30j,
       ROUND(100.0 * COUNT(DISTINCT o1.user_id) FILTER (WHERE o2.created_at <= o1.created_at + INTERVAL '60 days')
             / COUNT(DISTINCT o1.user_id), 2) AS pct_60j,
       ROUND(100.0 * COUNT(DISTINCT o2.user_id) / COUNT(DISTINCT o1.user_id), 2) AS pct_90j
FROM "Orders" o1
LEFT JOIN "Orders" o2 ON o2.user_id = o1.user_id
                     AND o2.status IN ('paid', 'shipped', 'delivered')
                     AND o2.created_at > o1.created_at
                     AND o2.created_at <= o1.created_at + INTERVAL '90 days'
WHERE o1.status IN ('paid', 'shipped', 'delivered')
  AND o1.user_id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM "Orders" o0
    WHERE o0.user_id = o1.user_id
      AND o0.status IN ('paid', 'shipped', 'delivered')
      AND o0.created_at < o1.created_at
  );

-- Défi 20
-- Quelles paires de variantes sont les plus fréquentes dans une même commande ? Comptez chaque paire une fois par commande


SELECT va.ref_commercial AS variante_a, pa.name AS nom_a,
       vb.ref_commercial AS variante_b, pb.name AS nom_b,
       COUNT(*) AS nb_commandes
FROM "OrderItem" a
JOIN "OrderItem" b ON b.order_id = a.order_id AND a.variant_id < b.variant_id
JOIN "Orders" o ON o.id = a.order_id
JOIN "Variant" va ON va.id = a.variant_id
JOIN "Variant" vb ON vb.id = b.variant_id
JOIN "Product" pa ON pa.id = va.product_id
JOIN "Product" pb ON pb.id = vb.product_id
WHERE o.status IN ('paid', 'shipped', 'delivered')
GROUP BY va.id, va.ref_commercial, pa.name, vb.id, vb.ref_commercial, pb.name
ORDER BY nb_commandes DESC
LIMIT 20;
