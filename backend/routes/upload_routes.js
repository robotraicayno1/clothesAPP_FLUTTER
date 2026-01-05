const express = require('express');
const multer = require('multer');
const path = require('path');
const uploadRouter = express.Router();

// Set up storage engine
const storage = multer.diskStorage({
    destination: './uploads/',
    filename: function (req, file, cb) {
        cb(null, file.fieldname + '-' + Date.now() + path.extname(file.originalname));
    }
});

// Init Upload
const upload = multer({
    storage: storage,
    limits: { fileSize: 50000000 }, // 50MB limit (Increased from 5MB)
    fileFilter: function (req, file, cb) {
        checkFileType(file, cb);
    }
}).single('image'); // 'image' is the field name

// Check File Type
function checkFileType(file, cb) {
    const filetypes = /jpeg|jpg|png|gif|webp/; // Added webp
    const extname = filetypes.test(path.extname(file.originalname).toLowerCase());
    // Remove strict mimetype check for now as it can be flaky with some phones
    // const mimetype = filetypes.test(file.mimetype);

    if (extname) {
        return cb(null, true);
    } else {
        console.log("File Type Error:", file.originalname, file.mimetype);
        cb('Error: Images Only! (jpeg, jpg, png, gif, webp)');
    }
}

// Upload endpoint
uploadRouter.post('/', (req, res) => {
    upload(req, res, (err) => {
        if (err) {
            console.log("Upload Error:", err); // Log the specific error
            res.status(400).json({ msg: err });
        } else {
            if (req.file == undefined) {
                console.log("Error: No file selected");
                res.status(400).json({ msg: 'No file selected!' });
            } else {
                console.log("File Uploaded:", req.file.filename);
                res.json({
                    msg: 'File Uploaded!',
                    url: `uploads/${req.file.filename}`
                });
            }
        }
    });
});

module.exports = uploadRouter;
