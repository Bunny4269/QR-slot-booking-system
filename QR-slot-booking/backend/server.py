from flask import Flask, request, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

# ==========================================
# MEMORY STORAGE
# ==========================================

booked_slots = []
verified_slots = []


# ==========================================
# HOME API
# ==========================================

@app.route('/', methods=['GET'])
def home():

    return jsonify({
        "success": True,
        "message": "QR Slot Booking Backend Running"
    })


# ==========================================
# GET ALL SLOT STATUS
# ==========================================

@app.route('/slots', methods=['GET'])
def get_slots():

    return jsonify({
        "success": True,
        "booked_slots": booked_slots,
        "verified_slots": verified_slots
    })


# ==========================================
# BOOK SLOTS
# ==========================================

@app.route('/book', methods=['POST'])
def book_slots():

    try:

        data = request.json

        if not data:
            return jsonify({
                "success": False,
                "message": "No data received"
            })

        slots = data.get("slots", [])
        name = data.get("name", "")

        if len(slots) == 0:
            return jsonify({
                "success": False,
                "message": "No slots selected"
            })

        # CHECK ALREADY BOOKED
        for slot in slots:

            if slot in booked_slots:

                return jsonify({
                    "success": False,
                    "message": f"{slot} already booked"
                })

        # SAVE BOOKINGS
        for slot in slots:

            if slot not in booked_slots:
                booked_slots.append(slot)

        return jsonify({
            "success": True,
            "message": f"Booking successful for {name}",
            "booked_slots": booked_slots
        })

    except Exception as e:

        return jsonify({
            "success": False,
            "message": str(e)
        })


# ==========================================
# VERIFY SLOTS
# ==========================================

@app.route('/verify', methods=['POST'])
def verify_slots():

    try:

        data = request.json

        if not data:
            return jsonify({
                "success": False,
                "message": "No data received"
            })

        slots = data.get("slots", [])

        if len(slots) == 0:
            return jsonify({
                "success": False,
                "message": "No slots provided"
            })

        for slot in slots:

            # ADD TO VERIFIED
            if slot not in verified_slots:
                verified_slots.append(slot)

        return jsonify({
            "success": True,
            "message": "Slots verified successfully",
            "verified_slots": verified_slots
        })

    except Exception as e:

        return jsonify({
            "success": False,
            "message": str(e)
        })


# ==========================================
# CLEAR ALL SLOTS
# ==========================================

@app.route('/clear', methods=['GET', 'POST'])
def clear_slots():

    booked_slots.clear()
    verified_slots.clear()

    return jsonify({
        "success": True,
        "message": "All slots cleared"
    })


# ==========================================
# CLEAR VERIFIED ONLY
# ==========================================

@app.route('/clear_verified', methods=['GET', 'POST'])
def clear_verified():

    verified_slots.clear()

    return jsonify({
        "success": True,
        "message": "Verified slots cleared"
    })


# ==========================================
# CLEAR BOOKED ONLY
# ==========================================

@app.route('/clear_booked', methods=['GET', 'POST'])
def clear_booked():

    booked_slots.clear()

    return jsonify({
        "success": True,
        "message": "Booked slots cleared"
    })


# ==========================================
# SERVER START
# ==========================================

if __name__ == '__main__':

    app.run(
        host='0.0.0.0',
        port=5000,
        debug=True
    )