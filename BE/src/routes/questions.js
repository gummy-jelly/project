const router = require('express').Router();
const pool   = require('../db');
const auth   = require('../middleware/auth');

// GET /api/questions?exam=SAA&page=1&limit=20
router.get('/', auth, async (req, res) => {
  try {
    const exam   = req.query.exam || 'SAA';
    const page   = Math.max(1, parseInt(req.query.page)  || 1);
    const limit  = Math.min(997, parseInt(req.query.limit) || 20);
    const offset = (page - 1) * limit;

    const [items] = await pool.query(
      `SELECT q.number, q.question_en, q.question_ko,
              q.options_en, q.options_ko,
              q.explanation_en, q.explanation_ko,
              q.is_translated, et.code AS category,
              t.name AS tag_name
       FROM questions q
       JOIN exam_types et ON q.exam_type_id = et.id
       LEFT JOIN tags t ON q.tag_id = t.id
       WHERE et.code = ?
       ORDER BY q.number
       LIMIT ? OFFSET ?`,
      [exam, limit, offset]
    );

    const [[{ total }]] = await pool.query(
      `SELECT COUNT(*) AS total
       FROM questions q
       JOIN exam_types et ON q.exam_type_id = et.id
       WHERE et.code = ?`,
      [exam]
    );

    res.json({ total, page, limit, items: items.map(parseOptions) });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: '서버 오류가 발생했습니다.' });
  }
});

// GET /api/questions/:number
router.get('/:number', auth, async (req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT q.*, et.code AS category, t.name AS tag_name
       FROM questions q
       JOIN exam_types et ON q.exam_type_id = et.id
       LEFT JOIN tags t ON q.tag_id = t.id
       WHERE q.number = ?`,
      [parseInt(req.params.number)]
    );
    if (rows.length === 0) {
      return res.status(404).json({ message: '문제를 찾을 수 없습니다.' });
    }
    const q = parseOptions(rows[0]);
    // 정답/해설은 submit 전까지 노출 안 함
    const { answer, explanation_en, explanation_ko, ...safe } = q;
    res.json(safe);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: '서버 오류가 발생했습니다.' });
  }
});

// POST /api/questions/:number/submit
router.post('/:number/submit', auth, async (req, res) => {
  try {
    const selected = (req.body.selected || '').toUpperCase();
    const userId   = req.user.id;

    if (!['A','B','C','D','E'].includes(selected)) {
      return res.status(400).json({ message: '보기를 선택해주세요.' });
    }

    const [rows] = await pool.query(
      'SELECT answer, explanation_en, explanation_ko FROM questions WHERE number = ?',
      [parseInt(req.params.number)]
    );
    if (rows.length === 0) {
      return res.status(404).json({ message: '문제를 찾을 수 없습니다.' });
    }

    const isCorrect = rows[0].answer === selected;

    if (isCorrect) {
      await pool.query(
        'UPDATE user_stats SET correct = correct + 1 WHERE user_id = ?',
        [userId]
      );
    } else {
      await pool.query(
        'UPDATE user_stats SET wrong = wrong + 1 WHERE user_id = ?',
        [userId]
      );
    }

    res.json({
      correct:        isCorrect,
      answer:         rows[0].answer,
      selected,
      explanation_en: rows[0].explanation_en || null,
      explanation_ko: rows[0].explanation_ko || null,
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: '서버 오류가 발생했습니다.' });
  }
});

function parseOptions(row) {
  return {
    ...row,
    options_en: typeof row.options_en === 'string'
      ? JSON.parse(row.options_en) : row.options_en,
    options_ko: row.options_ko
      ? (typeof row.options_ko === 'string' ? JSON.parse(row.options_ko) : row.options_ko)
      : null,
  };
}

module.exports = router;
