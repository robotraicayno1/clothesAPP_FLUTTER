const express = require('express');
const orderRouter = express.Router();
const { auth } = require('../middleware/auth_middleware');
const { admin } = require('../middleware/auth_middleware');
const Order = require('../models/order_model');
const User = require('../models/user_model');
const Product = require('../models/product_model'); // Need to check prices/stock eventually

// Create Order (Checkout)
orderRouter.post('/', auth, async (req, res) => {
    try {
        const { totalPrice, cart, voucherCode, discountAmount, address } = req.body;
        // In a real app, verify totalPrice on backend by fetching products. 
        // For this demo, we trust the client but basic structure is here.

        let products = [];
        for (let i = 0; i < cart.length; i++) {
            products.push({
                product: cart[i].product._id, // Assuming cart item structure from frontend
                quantity: cart[i].quantity,
            });
        }

        let order = new Order({
            userId: req.user,
            products: products,
            totalPrice: totalPrice,
            address: address,
            voucherCode: voucherCode || '',
            discountAmount: discountAmount || 0,
            status: 0, // Pending
        });

        order = await order.save();

        // Clear user cart
        let user = await User.findById(req.user);
        user.cart = [];
        await user.save();

        res.json(order);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

// Get My Orders
orderRouter.get('/my-orders', auth, async (req, res) => {
    try {
        const orders = await Order.find({ userId: req.user })
            .populate('products.product')
            .sort({ createdAt: -1 });
        res.json(orders);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

// Get All Orders (Admin)
orderRouter.get('/', auth, admin, async (req, res) => {
    try {
        console.log('Admin fetching all orders...');
        const orders = await Order.find({})
            .sort({ createdAt: -1 })
            .populate('products.product')
            .populate('userId', 'name email');
        res.json(orders);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

// Update Order Status (Admin or User Confirmation)
orderRouter.put('/:id/status', auth, async (req, res) => {
    try {
        const { status } = req.body;
        let order = await Order.findById(req.params.id);

        if (!order) {
            return res.status(404).json({ msg: "Order not found" });
        }

        // Check if user is admin
        const user = await User.findById(req.user);
        const isAdmin = user && user.type === 'admin';

        if (isAdmin) {
            order.status = status;
        } else {
            // Regular user can only confirm delivery (status 3) if current is 2
            if (status === 3 && order.status === 2 && order.userId.toString() === req.user) {
                order.status = 3;
            } else {
                return res.status(403).json({ msg: "Unauthorized status update" });
            }
        }

        await order.save();
        res.json(order);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

module.exports = orderRouter;
