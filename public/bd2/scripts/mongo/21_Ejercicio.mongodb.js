use("sample_airbnb");

db.listingsAndReviews.aggregate([
  {
    $match: {
      $expr: { $gt: [{ $size: "$amenities" }, 10] }
    }
  },
  {
    $count: "total_listings"
  }
]);