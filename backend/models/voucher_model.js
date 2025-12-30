const mongoose = require('mongoose');

const voucherSchema = new mongoose.Schema({
    code: {
        type: String,
        required: true,
        unique: true,
        uppercase: true,
        trim: true,
    },
    discountAmount: {
        type: Number,
        required: true,
        // Assuming fixed amount in VND, e.g., 50000
    },
    expiryDate: {
        type: Date,
        required: true,
    },
    isActive: {
        type: Boolean,
        default: true,
    },
    createdAt: {
        type: Date,
        default: Date.now,
    }
});

const Voucher = mongoose.model('Voucher', voucherSchema);
module.exports = Voucher;
