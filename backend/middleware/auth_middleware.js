const jwt = require('jsonwebtoken');
const User = require('../models/user_model');

// Middleware to verify JWT token
const auth = async (req, res, next) => {
    try {
        const token = req.header('x-auth-token');
        if (!token) return res.status(401).json({ msg: "No auth token, access denied" });

        const secret = process.env.JWT_SECRET || "your_jwt_secret_key_123";
        const verified = jwt.verify(token, secret);
        if (!verified) return res.status(401).json({ msg: "Token verification failed, authorization denied." });

        // Get user details
        const user = await User.findById(verified.id);
        if (!user) return res.status(404).json({ msg: "User not found" });

        req.user = verified.id;
        req.userName = user.name;
        req.userType = user.type;
        req.token = token;
        next();
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
};

// Middleware to verify Admin role
const admin = async (req, res, next) => {
    try {
        const user = await User.findById(req.user);
        if (!user) {
            console.log("Admin Check: User not found in DB for ID:", req.user);
            return res.status(404).json({ msg: "User not found" });
        }

        console.log(`Admin Check: User ${user.email} is type ${user.type}`);

        if (user.type !== 'admin') {
            console.log("Admin Check: REJECTED - User is not an admin");
            return res.status(401).json({ msg: "You are not an admin!" });
        }
        next();
    } catch (e) {
        console.error("Admin Check Error:", e.message);
        res.status(500).json({ error: e.message });
    }
};

module.exports = { auth, admin };
