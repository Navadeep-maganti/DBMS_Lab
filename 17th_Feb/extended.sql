-- Q1. Find full reporting tree as of 2017-06-01
WITH RECURSIVE tree AS (
    -- Roots (no manager at that date)
    SELECT e.emp_id, e.emp_name, NULL AS mgr_id, 0 AS depth
    FROM EMP e
    WHERE NOT EXISTS (
        SELECT 1
        FROM EMP_MANAGER_HISTORY h
        WHERE h.emp_id = e.emp_id
          AND '2017-06-01' BETWEEN h.valid_from 
                               AND COALESCE(h.valid_to, '9999-12-31')
    )

    UNION ALL

    SELECT e.emp_id, e.emp_name, h.mgr_id, t.depth + 1
    FROM EMP e
    JOIN EMP_MANAGER_HISTORY h
         ON e.emp_id = h.emp_id
    JOIN tree t
         ON h.mgr_id = t.emp_id
    WHERE '2017-06-01' BETWEEN h.valid_from
                          AND COALESCE(h.valid_to, '9999-12-31')
)
SELECT * FROM tree
ORDER BY depth, emp_id;

-- Q2. Find employees whose manager changed more than 2 times 
SELECT emp_id
FROM EMP_MANAGER_HISTORY
GROUP BY emp_id
HAVING COUNT(*) > 2;

-- Q3. Find employees who reported (directly or indirectly) to KING at any time 
WITH RECURSIVE hist_tree AS (
    SELECT emp_id, mgr_id, valid_from, valid_to
    FROM EMP_MANAGER_HISTORY
    WHERE mgr_id = 1

    UNION ALL

    SELECT h.emp_id, h.mgr_id, h.valid_from, h.valid_to
    FROM EMP_MANAGER_HISTORY h
    JOIN hist_tree t
      ON h.mgr_id = t.emp_id
)
SELECT DISTINCT emp_id
FROM hist_tree;

-- Q4. Detect illegal overlaps in manager history 
SELECT a.emp_id
FROM EMP_MANAGER_HISTORY a
JOIN EMP_MANAGER_HISTORY b
  ON a.emp_id = b.emp_id
 AND a.valid_from < COALESCE(b.valid_to,'9999-12-31')
 AND b.valid_from < COALESCE(a.valid_to,'9999-12-31')
 AND a.valid_from <> b.valid_from;

-- Q5. Find longest continuous reporting duration to same manager 
SELECT emp_id,
       mgr_id,
       MAX(DATEDIFF(COALESCE(valid_to, CURRENT_DATE), valid_from)) AS duration_days
FROM EMP_MANAGER_HISTORY
GROUP BY emp_id, mgr_id
ORDER BY duration_days DESC
LIMIT 1;

-- Q6. Salary increase immediately after manager change 
SELECT m.emp_id, m.valid_from AS change_date
FROM EMP_MANAGER_HISTORY m
JOIN EMP_SALARY_HISTORY s1
  ON s1.emp_id = m.emp_id
 AND s1.valid_to = m.valid_from
JOIN EMP_SALARY_HISTORY s2
  ON s2.emp_id = m.emp_id
 AND s2.valid_from = m.valid_from
WHERE s2.salary > s1.salary;

-- Q7. Find manager who had largest team on any single day in history 
WITH RECURSIVE team AS (
    SELECT emp_id, mgr_id
    FROM EMP_MANAGER_HISTORY
    WHERE '2018-01-01' BETWEEN valid_from 
                          AND COALESCE(valid_to,'9999-12-31')

    UNION ALL

    SELECT h.emp_id, h.mgr_id
    FROM EMP_MANAGER_HISTORY h
    JOIN team t ON h.mgr_id = t.emp_id
)
SELECT mgr_id, COUNT(*) AS team_size
FROM team
GROUP BY mgr_id
ORDER BY team_size DESC;

-- Q8. Find employees who were once their manager’s manager (cycle over time)
WITH RECURSIVE chain AS (
    SELECT emp_id, mgr_id
    FROM EMP_MANAGER_HISTORY

    UNION ALL

    SELECT c.emp_id, h.mgr_id
    FROM chain c
    JOIN EMP_MANAGER_HISTORY h
      ON c.mgr_id = h.emp_id
)
SELECT DISTINCT emp_id
FROM chain
WHERE emp_id = mgr_id;

-- Q9. For each year: Find maximum hierarchy depth
WITH RECURSIVE yearly_tree AS (
    SELECT 2017 AS yr, emp_id, 0 AS depth
    FROM EMP
    WHERE emp_id NOT IN (
        SELECT emp_id FROM EMP_MANAGER_HISTORY
        WHERE '2017-06-01' BETWEEN valid_from 
                              AND COALESCE(valid_to,'9999-12-31')
    )

    UNION ALL

    SELECT yt.yr, h.emp_id, yt.depth + 1
    FROM EMP_MANAGER_HISTORY h
    JOIN yearly_tree yt ON h.mgr_id = yt.emp_id
    WHERE '2017-06-01' BETWEEN h.valid_from 
                          AND COALESCE(h.valid_to,'9999-12-31')
)
SELECT yr, MAX(depth)
FROM yearly_tree
GROUP BY yr;

-- Q10. Find employees whose chain included both KING and BLAKE at different times
WITH RECURSIVE full_chain AS (
    SELECT emp_id, mgr_id
    FROM EMP_MANAGER_HISTORY

    UNION ALL

    SELECT c.emp_id, h.mgr_id
    FROM full_chain c
    JOIN EMP_MANAGER_HISTORY h
      ON c.mgr_id = h.emp_id
)
SELECT emp_id
FROM full_chain
WHERE mgr_id IN (1,2)
GROUP BY emp_id
HAVING COUNT(DISTINCT mgr_id) = 2;