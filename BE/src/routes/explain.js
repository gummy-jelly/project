const router = require('express').Router();
const pool   = require('../db');
const auth   = require('../middleware/auth');

// POST /api/questions/:number/explain
router.post('/:number', auth, async (req, res) => {
  try {
    const number = parseInt(req.params.number);

    const [rows] = await pool.query(
      'SELECT explanation_en, explanation_ko FROM questions WHERE number = ?',
      [number]
    );

    if (rows.length === 0) {
      return res.status(404).json({ message: '문제를 찾을 수 없습니다.' });
    }

    res.json({
      explanation_en: rows[0].explanation_en || null,
      explanation_ko: rows[0].explanation_ko || null,
    });

  } catch (err) {
    console.error(err);
    res.status(500).json({ message: '서버 오류가 발생했습니다.' });
  }
});

module.exports = router;
