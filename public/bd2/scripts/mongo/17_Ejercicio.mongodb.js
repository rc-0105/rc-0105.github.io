use("sample_airbnb");

db.listingsAndReviews.updateOne(
  { name: "Cabin con Vista al Lago" },
  {
    $set: {
      summary: "Cabaña actualizada con una nueva amenity."
    },
    $push: {
      amenities: "Smart TV"
    }
  }
);