import 'package:mysql1/mysql1.dart';

class DatabaseService {
  static final settings = ConnectionSettings(
    host: 'localhost', 
    port: 3306,
    user: 'lajim',
    password: '1234',
    db: 'course_recommendation'
  );

  static Future<MySqlConnection> getConnection() async {
    return await MySqlConnection.connect(settings);
  }


  static Future<Results> createStudent(String name, String email, String password, String major) async {
    final conn = await getConnection();
    try {
      return await conn.query(
        'INSERT INTO Student (Name, Email, Password, Major) VALUES (?, ?, ?, ?)',
        [name, email, password, major]
      );
    } finally {
      await conn.close();
    }
  }

  static Future<Map<String, dynamic>?> getStudent(int id) async {
    final conn = await getConnection();
    try {
      var results = await conn.query(
        'SELECT * FROM Student WHERE StudentID = ?',
        [id]
      );
      return results.isNotEmpty ? results.first.fields : null;
    } finally {
      await conn.close();
    }
  }


  static Future<List<Map<String, dynamic>>> getRecommendedCourses(int studentId) async {
    final conn = await getConnection();
    try {
      var results = await conn.query('''
        SELECT c.*, r.RecommendationReason 
        FROM Course c 
        JOIN Recommendation r ON c.CourseID = r.CourseID 
        WHERE r.StudentID = ?
      ''', [studentId]);
      
      return results.map((r) => r.fields).toList();
    } finally {
      await conn.close();
    }
  }

  static Future<void> enrollStudent(int studentId, int courseId) async {
    final conn = await getConnection();
    try {
      await conn.query('''
        INSERT INTO Enrollment (StudentID, CourseID, EnrollmentDate, Status)
        VALUES (?, ?, CURDATE(), 'Enrolled')
      ''', [studentId, courseId]);
    } finally {
      await conn.close();
    }
  }

  // Grade operations
  static Future<List<Map<String, dynamic>>> getStudentGrades(int studentId) async {
    final conn = await getConnection();
    try {
      var results = await conn.query('''
        SELECT c.CourseName, g.Grade 
        FROM Grade g
        JOIN Course c ON g.CourseID = c.CourseID
        WHERE g.StudentID = ?
      ''', [studentId]);
      
      return results.map((r) => r.fields).toList();
    } finally {
      await conn.close();
    }
  }


  static Future<void> addAchievement(int studentId, String achievementName) async {
    final conn = await getConnection();
    try {
      await conn.query('''
        INSERT INTO Achievement (StudentID, AchievementName, DateAchieved)
        VALUES (?, ?, CURDATE())
      ''', [studentId, achievementName]);
    } finally {
      await conn.close();
    }
  }

  static Future<List<Map<String, dynamic>>> getUnreadNotifications(int studentId) async {
    final conn = await getConnection();
    try {
      var results = await conn.query('''
        SELECT * FROM Notification 
        WHERE StudentID = ? AND Status = 'Unread'
        ORDER BY SentDate DESC
      ''', [studentId]);
      
      return results.map((r) => r.fields).toList();
    } finally {
      await conn.close();
    }
  }


  static Future<double?> getSuccessProbability(int studentId, int courseId) async {
    final conn = await getConnection();
    try {
      var results = await conn.query('''
        SELECT SuccessProbability 
        FROM AI_Prediction 
        WHERE StudentID = ? AND CourseID = ?
        ORDER BY PredictionDate DESC 
        LIMIT 1
      ''', [studentId, courseId]);
      
      return results.isNotEmpty ? results.first['SuccessProbability'] : null;
    } finally {
      await conn.close();
    }
  }


  static Future<double> getCourseRating(int courseId) async {
    final conn = await getConnection();
    try {
      var results = await conn.query('''
        SELECT AVG(Rating) as AverageRating 
        FROM CourseReview 
        WHERE CourseID = ?
      ''', [courseId]);
      
      return results.first['AverageRating'] ?? 0.0;
    } finally {
      await conn.close();
    }
  }
}
