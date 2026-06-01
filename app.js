const express = require('express');
const app = express();
const PORT = 3000;

app.get('/', (req, res) => {
    res.send('Hello DevSecOps, My App is running on Colima K8s!');
});

app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
});
