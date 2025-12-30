const express = require('express');
const Message = require('../models/message_model');
const User = require('../models/user_model');
const { auth } = require('../middleware/auth_middleware');
const router = express.Router();

// Send Message
router.post('/', auth, async (req, res) => {
    try {
        const { receiverId, text } = req.body;
        const senderId = req.user;

        let finalReceiverId = receiverId;
        if (receiverId === 'admin') {
            const admin = await User.findOne({ type: 'admin' });
            if (!admin) return res.status(404).json({ msg: "Admin not found" });
            finalReceiverId = admin._id;
        }

        const message = new Message({
            senderId,
            receiverId: finalReceiverId,
            text,
        });

        await message.save();
        res.json(message);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

// Get Chat History with a specific user
router.get('/history/:userId', auth, async (req, res) => {
    try {
        const myId = req.user;
        let otherId = req.params.userId;

        if (otherId === 'admin') {
            const admin = await User.findOne({ type: 'admin' });
            if (!admin) return res.json([]);
            otherId = admin._id;
        }

        const messages = await Message.find({
            $or: [
                { senderId: myId, receiverId: otherId },
                { senderId: otherId, receiverId: myId }
            ]
        }).sort({ createdAt: 1 });

        res.json(messages);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

// Get Admin Conversations (Unique users who messaged)
router.get('/admin/conversations', auth, async (req, res) => {
    try {
        const user = await User.findById(req.user);
        if (!user || user.type !== 'admin') {
            return res.status(403).json({ msg: "Forbidden" });
        }

        // Find unique senderIds who sent messages to anyone (usually admin)
        // Or more precisely, find all unique users involved in chats
        const adminId = user._id;

        const conversations = await Message.aggregate([
            {
                $match: {
                    $or: [
                        { receiverId: adminId },
                        { senderId: adminId }
                    ]
                }
            },
            {
                $sort: { createdAt: -1 }
            },
            {
                $group: {
                    _id: {
                        $cond: [
                            { $eq: ["$senderId", adminId] },
                            "$receiverId",
                            "$senderId"
                        ]
                    },
                    lastMessage: { $first: "$text" },
                    lastTime: { $first: "$createdAt" }
                }
            },
            {
                $lookup: {
                    from: 'users',
                    localField: '_id',
                    foreignField: '_id',
                    as: 'userInfo'
                }
            },
            {
                $unwind: {
                    path: '$userInfo',
                    preserveNullAndEmptyArrays: false
                }
            },
            {
                $project: {
                    userId: '$_id',
                    name: '$userInfo.name',
                    email: '$userInfo.email',
                    lastMessage: 1,
                    lastTime: 1
                }
            },
            {
                $sort: { lastTime: -1 }
            }
        ]);

        res.json(conversations);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

module.exports = router;
