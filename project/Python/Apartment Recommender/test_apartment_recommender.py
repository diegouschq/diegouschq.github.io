from apartment_recommender import classify_occupancy, filter_by_budget


def test_classify_occupancy():
    assert classify_occupancy(0) == "Low"
    assert classify_occupancy(60) == "Low"
    assert classify_occupancy(61) == "Medium"
    assert classify_occupancy(148) == "Medium"
    assert classify_occupancy(149) == "High"


def test_filter_by_budget():
    sample = [
        {"Apartment Name": "A", "Gender": "F", "Price": 1000, "Ocupancy": 50, "Distance": 0.30},
        {"Apartment Name": "B", "Gender": "F", "Price": 1500, "Ocupancy": 70, "Distance": 0.40},
        {"Apartment Name": "C", "Gender": "F", "Price": 2000, "Ocupancy": 200, "Distance": 0.20},
    ]

    r1 = filter_by_budget(sample, 1500)
    assert len(r1) == 2
    assert all(a["Price"] <= 1500 for a in r1)

    r2 = filter_by_budget(sample, 999)
    assert len(r2) == 0
    assert r2 == []