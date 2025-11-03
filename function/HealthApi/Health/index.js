module.exports = async function (context, req) {
  const now = new Date().toISOString();
  context.res = {
    status: 200,
    headers: { "Content-Type": "application/json" },
    body: { status: "ok", ts: now }
  };
};