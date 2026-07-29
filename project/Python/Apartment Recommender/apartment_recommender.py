import csv
import os
from typing import List, Dict

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_FILE = os.path.join(BASE_DIR, "rent.csv")

def load_apartments_csv(filename: str) -> List[Dict]:
    """Load apartments from a CSV into a list of dictionaries with correct types."""
    apartments = []
    with open(filename, mode="r", encoding="utf-8-sig", newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            # CSV uses 'Ocupancy' (typo) — keep it consistent everywhere.
            apartments.append({
                "Apartment Name": row["Apartment Name"].strip(),
                "Gender": row["Gender"].strip().upper(),
                "Price": int(row["Price"]),
                "Ocupancy": int(row["Ocupancy"]),
                "Distance": float(row["Distance"]),
            })
    return apartments


def normalize_text(s: str) -> str:
    return s.strip().lower()


def ask_int(prompt: str) -> int:
    while True:
        raw = input(prompt).strip()
        try:
            return int(raw)
        except ValueError:
            print("Please enter a whole number (example: 24).")


def ask_choice(prompt: str, allowed: List[str]) -> str:
    """Force user to choose exactly one of allowed values (case-insensitive)."""
    allowed_norm = {normalize_text(a): a for a in allowed}
    while True:
        ans = normalize_text(input(prompt))
        if ans in allowed_norm:
            return allowed_norm[ans]
        print(f"Invalid option. Please type one of: {', '.join(allowed)}")


def classify_occupancy(n: int) -> str:
    """Return Low/Medium/High based on project rule."""
    if 0 <= n <= 60:
        return "Low"
    if 61 <= n <= 148:
        return "Medium"
    return "High"


def filter_by_gender(apts: List[Dict], gender: str) -> List[Dict]:
    return [a for a in apts if a["Gender"] == gender]


def filter_by_budget(apts: List[Dict], budget: int) -> List[Dict]:
    return [a for a in apts if a["Price"] <= budget]


def filter_by_distance(apts: List[Dict], max_distance: float = 0.39) -> List[Dict]:
    return [a for a in apts if a["Distance"] <= max_distance]


def filter_by_occupancy_level(apts: List[Dict], level: str) -> List[Dict]:
    level = level.capitalize()
    return [a for a in apts if classify_occupancy(a["Ocupancy"]) == level]


def choose_priority(available: List[str]) -> str:
    """available contains strings '1','2','3' representing price/distance/occupancy."""
    mapping = {"1": "Price", "2": "Distance", "3": "Occupancy"}
    prompt_lines = ["Choose a priority number from the available options:"]
    for num in available:
        prompt_lines.append(f"  {num}. {mapping[num]}")
    prompt_lines.append("Your choice: ")
    return ask_choice("\n".join(prompt_lines), allowed=available)


def apply_priority_filter(apts: List[Dict], priority_num: str) -> List[Dict]:
    """Apply one priority filter. If it would produce zero results (except budget), keep original."""
    if priority_num == "1":
        # Budget must succeed: keep asking until at least one option exists.
        while True:
            budget = ask_int("What is your maximum monthly budget (number)? ")
            filtered = filter_by_budget(apts, budget)
            if filtered:
                return filtered
            print("No apartments match that budget. Please enter a different amount available in the data set.")

    if priority_num == "2":
        filtered = filter_by_distance(apts, 0.39)
        if filtered:
            return filtered
        print("No apartments matched Distance <= 0.39. Keeping previous results.")
        return apts

    if priority_num == "3":
        level = ask_choice("Choose occupancy level (Low, Medium, High): ", ["Low", "Medium", "High"])
        filtered = filter_by_occupancy_level(apts, level)
        if filtered:
            return filtered
        print("No apartments matched that occupancy level. Keeping previous results.")
        return apts

    # Should never happen due to validation
    return apts


def format_results(apts: List[Dict], limit: int = 15) -> str:
    """Format results, sorted by Price then Distance, showing up to `limit` rows."""
    if not apts:
        return "No results found."

    apts_sorted = sorted(apts, key=lambda a: (a["Price"], a["Distance"]))
    lines = []
    for a in apts_sorted[:limit]:
        lines.append(
            f"- {a['Apartment Name']} | Price: {a['Price']} | Distance: {a['Distance']:.2f} | Ocupancy: {a['Ocupancy']}"
        )
    if len(apts_sorted) > limit:
        lines.append(f"...and {len(apts_sorted) - limit} more.")
    return "\n".join(lines)


def main() -> None:
    apartments = load_apartments_csv(DATA_FILE)

    age = ask_int("How old are you? ")
    if age >= 26:
        print("You are 26 or older. Please contact BYUI Housing for other recommendations.")
        return

    gender = ask_choice("What is your gender for housing options? (F/M): ", ["F", "M"])
    filtered = filter_by_gender(apartments, gender)

    if not filtered:
        # Extremely unlikely with your dataset, but keep it safe.
        print("No apartments found for that gender in the dataset.")
        return

    # Priority #1
    available = ["1", "2", "3"]
    first_choice = choose_priority(available)
    filtered_after_first = apply_priority_filter(filtered, first_choice)

    # Priority #2 (only unselected options)
    remaining = [x for x in available if x != first_choice]
    second_choice = choose_priority(remaining)

    # Try applying second filter; if it fails/empties, ignore and keep first filter results.
    try:
        filtered_after_second = apply_priority_filter(filtered_after_first, second_choice)
        if not filtered_after_second:
            filtered_final = filtered_after_first
        else:
            filtered_final = filtered_after_second
    except Exception:
        filtered_final = filtered_after_first

    print("\nCongratulations! These are the following apartments that complete the requirements that you look for:\n")
    print(format_results(filtered_final))


if __name__ == "__main__":
    main()