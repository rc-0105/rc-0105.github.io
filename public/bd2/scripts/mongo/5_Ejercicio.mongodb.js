const existente = db.listingsAndReviews.findOne({}, { _id: 1 })

db.listingsAndReviews.insertOne({
  _id: existente._id,
  name: "Intento Duplicado",
  price: NumberDecimal("99.00")
})