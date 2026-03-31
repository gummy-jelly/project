const router = require('express').Router();
const pool   = require('../db');
const auth   = require('../middleware/auth');

// GET /api/stats/me
router.get('/me', auth, async (req, res) => {
  try {
    const [rows] = await pool.query(
      'SELECT correct, wrong FROM user_stats WHERE user_id = ?',
      [req.user.id]
    );
    if (rows.length === 0) {
      return res.json({ correct: 0, wrong: 0, total: 0, accuracy: 0 });
    }
    const { correct, wrong } = rows[0];
    const total    = correct + wrong;
    const accuracy = total > 0 ? Math.round((correct / total) * 1000) / 10 : 0;
    res.json({ correct, wrong, total, accuracy });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: '서버 오류가 발생했습니다.' });
  }
});

// GET /api/stats/leaderboard?type=total&limit=5
router.get('/leaderboard', auth, async (req, res) => {
  const type  = req.query.type  || 'total';
  const limit = Math.min(100, parseInt(req.query.limit) || 5);

  const orderMap = {
    total:    '(s.correct + s.wrong) DESC',
    correct:  's.correct DESC',
    accuracy: 'accuracy DESC',
  };

  if (!orderMap[type]) {
    return res.status(400).json({ message: 'type은 total | correct | accuracy 중 하나' });
  }

  try {
    const [rows] = await pool.query(`
      SELECT
        u.id,
        u.email,
        s.correct,
        s.wrong,
        (s.correct + s.wrong) AS total,
        CASE
          WHEN (s.correct + s.wrong) = 0 THEN 0
          ELSE ROUND(s.correct / (s.correct + s.wrong) * 100, 1)
        END AS accuracy
      FROM user_stats s
      JOIN users u ON s.user_id = u.id
      ORDER BY ${orderMap[type]}
      LIMIT ?
    `, [limit]);
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: '서버 오류가 발생했습니다.' });
  }
});

module.exports = router;
