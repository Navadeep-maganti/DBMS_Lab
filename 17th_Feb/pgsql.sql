-- # 1. Find total employees under each root 
WITH RECURSIVE emp_tree AS (
    SELECT emp_id, emp_name, mgr_id, emp_id AS root_id
    FROM EMP
    WHERE mgr_id IS NULL

    UNION ALL

    SELECT e.emp_id, e.emp_name, e.mgr_id, t.root_id
    FROM EMP e
    JOIN emp_tree t ON e.mgr_id = t.emp_id
)
SELECT root_id, COUNT(*) - 1 AS total_subordinates
FROM emp_tree
GROUP BY root_id;


-- # 2. Find deepest employee from each root 
WITH RECURSIVE emp_depth AS (
    SELECT emp_id, emp_name, mgr_id,
           emp_id AS root_id,
           0 AS depth
    FROM EMP
    WHERE mgr_id IS NULL

    UNION ALL

    SELECT e.emp_id, e.emp_name, e.mgr_id,
           d.root_id,
           d.depth + 1
    FROM EMP e
    JOIN emp_depth d ON e.mgr_id = d.emp_id
)
SELECT *
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY root_id ORDER BY depth DESC) rn
    FROM emp_depth
) x
WHERE rn = 1;

-- # 3. Find employees earning more than entire manager chain 
WITH RECURSIVE mgr_chain AS (
    SELECT emp_id, emp_name, mgr_id, salary,
           emp_id AS original_emp,
           mgr_id AS current_mgr
    FROM EMP

    UNION ALL

    SELECT m.emp_id, m.emp_name, m.mgr_id, m.salary,
           c.original_emp,
           m.mgr_id
    FROM mgr_chain c
    JOIN EMP m ON c.current_mgr = m.emp_id
)
SELECT e.emp_id, e.emp_name
FROM EMP e
WHERE e.salary > ALL (
    SELECT salary
    FROM mgr_chain
    WHERE original_emp = e.emp_id
      AND emp_id <> e.emp_id
);

-- # 4. Detect cycles 
WITH RECURSIVE cycle_check AS (
    SELECT emp_id, mgr_id,
           CAST(emp_id AS CHAR(200)) AS path
    FROM EMP

    UNION ALL

    SELECT e.emp_id, e.mgr_id,
           CONCAT(c.path, ',', e.emp_id)
    FROM EMP e
    JOIN cycle_check c ON e.emp_id = c.mgr_id
    WHERE FIND_IN_SET(e.emp_id, c.path) = 0
)
SELECT *
FROM cycle_check
WHERE FIND_IN_SET(mgr_id, path) > 0;

-- # 5. Find manager with largest subtree 
WITH RECURSIVE subtree AS (
    SELECT emp_id, emp_id AS manager_id
    FROM EMP

    UNION ALL

    SELECT e.emp_id, s.manager_id
    FROM EMP e
    JOIN subtree s ON e.mgr_id = s.emp_id
)
SELECT manager_id, COUNT(*) - 1 AS total_subordinates
FROM subtree
GROUP BY manager_id
ORDER BY total_subordinates DESC
LIMIT 1;

-- # 6. Find employees not connected to any root
WITH RECURSIVE connected AS (
    SELECT emp_id
    FROM EMP
    WHERE mgr_id IS NULL

    UNION ALL

    SELECT e.emp_id
    FROM EMP e
    JOIN connected c ON e.mgr_id = c.emp_id
)
SELECT *
FROM EMP
WHERE emp_id NOT IN (SELECT emp_id FROM connected);
