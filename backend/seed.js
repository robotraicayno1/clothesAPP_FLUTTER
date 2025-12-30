const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const User = require('./models/user_model');
const Product = require('./models/product_model');

const DB_URI = "mongodb://0.0.0.0:27017/clothesapp";

const seedDatabase = async () => {
    try {
        await mongoose.connect(DB_URI);
        console.log("Connected to MongoDB...");

        // === SEED USERS ===
        // Normal User
        let existingUser = await User.findOne({ email: "test@example.com" });
        if (!existingUser) {
            const hashedPassword = await bcrypt.hash("password123", 8);
            const user = new User({
                name: "Test User",
                email: "test@example.com",
                password: hashedPassword,
                type: "user",
            });
            await user.save();
            console.log("Test user added.");
        }

        // Admin User
        const adminData = {
            name: "Admin Manager",
            email: "admin@clothes.com",
            type: "admin",
        };
        const adminPassword = await bcrypt.hash("admin123", 8);

        let adminUser = await User.findOne({ email: adminData.email });
        if (adminUser) {
            adminUser.type = "admin"; // Ensure type is set
            adminUser.password = adminPassword; // Reset password to be sure
            await adminUser.save();
            console.log("Admin user updated.");
        } else {
            const admin = new User({
                ...adminData,
                password: adminPassword,
            });
            await admin.save();
            console.log("Admin user added (admin@clothes.com / admin123).");
        }

        // === SEED PRODUCTS ===
        const productCount = await Product.countDocuments();

        // Update EXISTING products to have default fields
        const updateResult = await Product.updateMany(
            { gender: { $exists: false } },
            {
                $set: {
                    gender: 'Unisex',
                    colors: ['Black', 'White'],
                    sizes: ['S', 'M', 'L', 'XL']
                }
            }
        );
        console.log(`Updated ${updateResult.modifiedCount} existing products with new fields.`);

        if (productCount === 0) {
            const products = [
                {
                    name: "Áo Thun Nam Trắng Basic",
                    description: "Áo thun cotton 100% thoáng mát, phong cách tối giản.",
                    price: 150000,
                    imageUrl: "https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60",
                    category: "Men",
                    gender: "Men",
                    colors: ["White", "Black"],
                    sizes: ["S", "M", "L", "XL"],
                    isFeatured: true,
                    isBestSeller: true,
                },
                {
                    name: "Quần Jean Nữ Ống Rộng",
                    description: "Quần jean thời trang, tôn dáng, chất liệu denim cao cấp.",
                    price: 350000,
                    imageUrl: "https://images.unsplash.com/photo-1541099649105-f69ad21f3246?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60",
                    category: "Women",
                    gender: "Women",
                    colors: ["Blue", "Light Blue"],
                    sizes: ["S", "M", "L"],
                    isFeatured: true,
                    isBestSeller: false,
                },
                {
                    name: "Áo Sơ Mi Công Sở",
                    description: "Áo sơ mi lịch sự, phù hợp đi làm và đi học.",
                    price: 250000,
                    imageUrl: "https://images.unsplash.com/photo-1563630381190-77c336ea545a?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60",
                    category: "Shirts",
                    gender: "Men",
                    colors: ["White", "Blue"],
                    sizes: ["M", "L", "XL"],
                    isFeatured: false,
                    isBestSeller: true,
                },
                {
                    name: "Quần Short Kaki Nam",
                    description: "Thoải mái, năng động cho mùa hè.",
                    price: 180000,
                    imageUrl: "https://images.unsplash.com/photo-1591195853828-11db59a44f6b?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60",
                    category: "Pants",
                    gender: "Men",
                    colors: ["Beige", "Black", "Navy"],
                    sizes: ["30", "31", "32", "33"],
                    isFeatured: true,
                    isBestSeller: false,
                },
                {
                    name: "Đầm Maxi Đi Biển",
                    description: "Đầm dài thướt tha, họa tiết hoa nhí.",
                    price: 450000,
                    imageUrl: "https://images.unsplash.com/photo-1496747611176-843222e1e57c?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60",
                    category: "Women",
                    gender: "Women",
                    colors: ["Red", "Floral"],
                    sizes: ["S", "M"],
                    isFeatured: true,
                    isBestSeller: true,
                },
            ];

            await Product.insertMany(products);
            console.log("Added 5 sample products.");
        } else {
            console.log("Products already exist. Skipping new product seed.");
        }

        // === SEED VOUCHERS ===
        const Voucher = require('./models/voucher_model');
        const voucherCount = await Voucher.countDocuments();
        if (voucherCount === 0) {
            const vouchers = [
                {
                    code: "SALE50",
                    discountAmount: 50000,
                    expiryDate: new Date(new Date().setMonth(new Date().getMonth() + 1)), // 1 month from now
                    isActive: true
                },
                {
                    code: "WELCOME20",
                    discountAmount: 20000,
                    expiryDate: new Date(new Date().setMonth(new Date().getMonth() + 2)),
                    isActive: true
                },
                {
                    code: "TET2025",
                    discountAmount: 100000,
                    expiryDate: new Date("2025-02-28"),
                    isActive: true
                }
            ];
            await Voucher.insertMany(vouchers);
            console.log("Added 3 sample vouchers.");
        }

    } catch (e) {
        console.error("Error seeding database:", e);
    } finally {
        await mongoose.disconnect();
        process.exit(0);
    }
};

seedDatabase();
