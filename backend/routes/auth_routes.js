const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/user_model');
const router = express.Router();

// Secret key for JWT (in production, use environment variable)
const JWT_SECRET = process.env.JWT_SECRET || 'your_jwt_secret_key_123';

// SIGNUP Route
router.post('/signup', async (req, res) => {
    try {
        const { name, email, password } = req.body;

        // Check if user already exists
        const existingUser = await User.findOne({ email });
        if (existingUser) {
            return res.status(400).json({ msg: 'User already exists with this email.' });
        }

        // Hash password
        const hashedPassword = await bcrypt.hash(password, 8);

        // Create new user
        let user = new User({
            name,
            email,
            password: hashedPassword,
        });

        user = await user.save();

        res.json({ msg: 'User created successfully', userId: user._id });
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

// LOGIN Route
router.post('/login', async (req, res) => {
    try {
        const { email, password } = req.body;

        // Find user
        const user = await User.findOne({ email });
        if (!user) {
            return res.status(400).json({ msg: 'User with this email does not exist.' });
        }

        // Check password
        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch) {
            return res.status(400).json({ msg: 'Incorrect password.' });
        }

        // Generate Token
        const token = jwt.sign({ id: user._id }, JWT_SECRET);

        res.json({ token, user: { id: user._id, name: user.name, email: user.email, type: user.type } });
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

module.exports = router;
