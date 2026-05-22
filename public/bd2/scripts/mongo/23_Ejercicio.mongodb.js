use("sample_airbnb");

db.listingsAndReviews.aggregate([
  { $unwind: "$amenities" },
  {
    $group: {
      _id: "$amenities",
      frequency: { $sum: 1 }
    }
  },
  { $sort: { frequency: -1 } },
  { $limit: 5 }
]);