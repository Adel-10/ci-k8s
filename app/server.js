const express = require('express');
const app = express();
app.get('/', (_req, res) => res.send('CI/CD on K8s via Jenkins + Docker!'));
app.listen(8080, () => console.log('Listening on 8080'));