const cors = require("cors")({origin: true});
const {onRequest} = require("firebase-functions/v2/https");

const SEARCH_FIELDS =
  "code,product_name,product_name_he,nutriments,categories_tags,brands";

exports.foodSearch = onRequest({cors: true, region: "us-central1"}, async (req, res) => {
  return cors(req, res, async () => {
    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }

    const query = (req.query.q || req.query.search_terms || "").toString().trim();
    if (query.length < 2) {
      res.status(400).json({error: "Query must be at least 2 characters"});
      return;
    }

    const pageSize = Math.min(
      parseInt(req.query.page_size || "25", 10) || 25,
      50,
    );

    const searchUrl = new URL("https://search.openfoodfacts.org/search");
    searchUrl.searchParams.set("q", query);
    searchUrl.searchParams.set("page_size", String(pageSize));
    searchUrl.searchParams.set("fields", SEARCH_FIELDS);

    try {
      const response = await fetch(searchUrl, {
        headers: {"User-Agent": "FitFlow/1.0 (food search proxy)"},
      });
      const body = await response.text();
      res.status(response.status);
      res.set("Content-Type", "application/json");
      res.send(body);
    } catch (error) {
      res.status(502).json({
        error: "Failed to reach Open Food Facts search",
        details: String(error),
      });
    }
  });
});
