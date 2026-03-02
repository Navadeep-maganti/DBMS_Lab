import os
os.environ["PATH"] = r"C:\Program Files\Graphviz\bin;" + os.environ.get("PATH", "")

from graphviz import Digraph

dot = Digraph(
    name="University_Academic_Management_ER",
    format="png",
    graph_attr={"rankdir": "TB", "splines": "ortho"},
    node_attr={"fontname": "Helvetica"},
    edge_attr={"fontname": "Helvetica"}
)

# ==============================
# Helper Functions
# ==============================

def entity(name, attributes):
    label = f"<<TABLE BORDER='1' CELLBORDER='0' CELLSPACING='0'>"
    label += f"<TR><TD><B>{name}</B></TD></TR>"
    for attr in attributes:
        label += f"<TR><TD ALIGN='LEFT'>{attr}</TD></TR>"
    label += "</TABLE>>"
    dot.node(name, label=label, shape="plaintext")

def weak_entity(name, attributes):
    label = f"<<TABLE BORDER='2' CELLBORDER='0' CELLSPACING='0'>"
    label += f"<TR><TD><B>{name}</B></TD></TR>"
    for attr in attributes:
        label += f"<TR><TD ALIGN='LEFT'>{attr}</TD></TR>"
    label += "</TABLE>>"
    dot.node(name, label=label, shape="plaintext")

def relationship(name, identifying=False):
    dot.node(
        name,
        label=name,
        shape="diamond",
        peripheries="2" if identifying else "1"
    )

def connect(left, rel, right, left_card="", right_card=""):
    dot.edge(left, rel, label=left_card)
    dot.edge(rel, right, label=right_card)

# ==============================
# CORE ENTITIES
# ==============================

entity("PROGRAM", [
    "ProgramID (PK)",
    "ProgramName",
    "DegreeType"
])

entity("REGULATION", [
    "RegulationID (PK)",
    "Version",
    "StartYear",
    "EndYear",
    "DropDeadline"
])

entity("DEPARTMENT", [
    "DeptID (PK)",
    "DeptName"
])

entity("COURSE", [
    "CourseID (PK)",
    "Title",
    "Credits"
])

entity("FACULTY", [
    "FacultyID (PK)",
    "Name",
    "Designation"
])

entity("STUDENT", [
    "StudentID (PK)",
    "Name",
    "AdmissionYear"
])

# ==============================
# CURRICULUM & ACADEMIC STRUCTURE
# ==============================

entity("REGULATION_COURSE", [
    "RegulationID (FK)",
    "CourseID (FK)",
    "SemesterNo"
])

entity("ASSESSMENT_PLAN", [
    "AssessmentType",
    "MaxMarks",
    "Weightage"
])

# ==============================
# SECTION & ENROLLMENT
# ==============================

weak_entity("SECTION", [
    "SectionNo (Partial Key)",
    "Semester",
    "AcademicYear",
    "Capacity",
    "SectionStatus"
])

weak_entity("ENROLLMENT", [
    "EnrollmentStatus"
])

entity("GRADE", [
    "LetterGrade",
    "GradePoint"
])

# ==============================
# TIMETABLE STRUCTURE
# ==============================

entity("TIMESLOT", [
    "SlotID (PK)",
    "Day",
    "StartTime",
    "EndTime"
])

entity("ROOM", [
    "RoomID (PK)",
    "Building",
    "Capacity"
])

weak_entity("CLASS_MEETING", [
    "MeetingNo (Partial Key)",
    "SessionType"
])

# ==============================
# ASSESSMENT EXECUTION
# ==============================

weak_entity("ASSESSMENT", [
    "AssessmentNo (Partial Key)",
    "AssessmentType"
])

weak_entity("MARK", [
    "MarksObtained"
])

# ==============================
# RELATIONSHIPS
# ==============================

relationship("HAS_REGULATION")
relationship("BELONGS_TO")
relationship("OFFERS")
relationship("CURRICULUM_OF", identifying=True)
relationship("HAS_SECTION", identifying=True)
relationship("TEACHES")
relationship("ENROLLED_IN", identifying=True)
relationship("FOLLOWS", identifying=True)
relationship("HAS_ASSESSMENT", identifying=True)
relationship("RECORDS_MARK", identifying=True)
relationship("RESULTS_IN")
relationship("HAS_MEETING", identifying=True)
relationship("OCCURS_IN")
relationship("HELD_IN")

# ==============================
# CONNECTIONS
# ==============================

# Program & Regulation
connect("PROGRAM", "HAS_REGULATION", "REGULATION", "1", "N")

# Department & Course
connect("DEPARTMENT", "OFFERS", "COURSE", "1", "N")

# Regulation Curriculum
connect("REGULATION", "CURRICULUM_OF", "REGULATION_COURSE", "1", "N")
connect("COURSE", "CURRICULUM_OF", "REGULATION_COURSE", "1", "N")

# Assessment Plan
connect("REGULATION_COURSE", "FOLLOWS", "ASSESSMENT_PLAN", "1", "N")

# Course Sections
connect("COURSE", "HAS_SECTION", "SECTION", "1", "N")

# Faculty Teaching
connect("FACULTY", "TEACHES", "SECTION", "1", "N")

# Student Program & Regulation
connect("STUDENT", "BELONGS_TO", "PROGRAM", "N", "1")
connect("STUDENT", "HAS_REGULATION", "REGULATION", "N", "1")

# Enrollment
connect("STUDENT", "ENROLLED_IN", "ENROLLMENT", "1", "N")
connect("SECTION", "ENROLLED_IN", "ENROLLMENT", "1", "N")

# Assessment Execution
connect("SECTION", "HAS_ASSESSMENT", "ASSESSMENT", "1", "N")
connect("ENROLLMENT", "RECORDS_MARK", "MARK", "1", "N")
connect("ASSESSMENT", "RECORDS_MARK", "MARK", "1", "N")

# Grades
connect("ENROLLMENT", "RESULTS_IN", "GRADE", "1", "0..1")

# Timetable
connect("SECTION", "HAS_MEETING", "CLASS_MEETING", "1", "N")
connect("CLASS_MEETING", "OCCURS_IN", "TIMESLOT", "N", "1")
connect("CLASS_MEETING", "HELD_IN", "ROOM", "N", "1")

# ==============================
# RENDER
# ==============================

dot.render("University_Academic_Management_ER", cleanup=True)
print("ER diagram generated successfully.")
