const express = require('express');
const Voucher = require('../models/voucher_model');
const { admin, auth } = require('../middleware/auth_middleware');
const router = express.Router();

// Create Voucher (Admin Only)
router.post('/', auth, admin, async (req, res) => {
    try {
        const { code, discountAmount, expiryDate } = req.body;

        const voucher = new Voucher({
            code,
            discountAmount,
            expiryDate,
        });

        await voucher.save();
        res.json(voucher);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

// Get All Vouchers
router.get('/', async (req, res) => {
    try {
        const vouchers = await Voucher.find({}).sort({ createdAt: -1 });
        res.json(vouchers);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

// Validate Voucher (optional helper for checkout)
router.post('/validate', async (req, res) => {
    try {
        const { code } = req.body;
        const voucher = await Voucher.findOne({ code });

        if (!voucher) {
            return res.status(400).json({ msg: "Voucher không tồn tại!" });
        }

        if (new Date() > voucher.expiryDate) {
            return res.status(400).json({ msg: "Voucher đã hết hạn!" });
        }

        if (!voucher.isActive) {
            return res.status(400).json({ msg: "Voucher không khả dụng!" });
        }

        res.json(voucher);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

// Delete Voucher (Admin Only)
router.delete('/:id', auth, admin, async (req, res) => {
    try {
        const voucher = await Voucher.findByIdAndDelete(req.params.id);
        if (!voucher) return res.status(404).json({ msg: "Voucher not found" });
        res.json({ msg: "Voucher deleted successfully" });
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

module.exports = router;
