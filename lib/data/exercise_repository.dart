import '../models/exercise.dart';

class ExerciseRepository {
  static final List<Exercise> exercises = [
    const Exercise(
      id: 1,
      name: 'סקוואט',
      category: 'רגליים',
      muscleGroup: 'רגליים וישבן',
      instructions:
      'לעמוד ברוחב כתפיים, לרדת עם הישבן לאחור, לשמור על גב ישר ולעלות בחזרה.',
    ),
    const Exercise(
      id: 2,
      name: 'לאנג׳ים',
      category: 'רגליים',
      muscleGroup: 'רגליים וישבן',
      instructions:
      'לקחת צעד קדימה, לרדת עד ששתי הברכיים כפופות, ולחזור לעמידה.',
    ),
    const Exercise(
      id: 3,
      name: 'היפ טראסט',
      category: 'ישבן',
      muscleGroup: 'ישבן',
      instructions:
      'להניח את הגב העליון על ספסל, כפות רגליים על הקרקע, להרים את האגן וללחוץ עם הישבן למעלה.',
    ),
    const Exercise(
      id: 4,
      name: 'דדליפט רומני',
      category: 'רגליים',
      muscleGroup: 'המסטרינג וישבן',
      instructions:
      'להחזיק משקל מול הגוף, להוריד אותו לאורך הרגליים עם גב ישר ולעלות בחזרה.',
    ),
    const Exercise(
      id: 5,
      name: 'לחיצת חזה',
      category: 'חזה',
      muscleGroup: 'חזה ויד אחורית',
      instructions:
      'לשכב על ספסל, להוריד את המשקל לקו החזה ולדחוף למעלה.',
    ),
    const Exercise(
      id: 6,
      name: 'פרפר חזה',
      category: 'חזה',
      muscleGroup: 'חזה',
      instructions:
      'לשמור על ידיים מעט כפופות, לפתוח לצדדים ולסגור חזרה בתנועה מבוקרת.',
    ),
    const Exercise(
      id: 7,
      name: 'פלאנק',
      category: 'בטן',
      muscleGroup: 'ליבה',
      instructions:
      'להישען על אמות וכפות רגליים, לשמור על גוף ישר ובטן אסופה.',
    ),
    const Exercise(
      id: 8,
      name: 'כפיפות בטן',
      category: 'בטן',
      muscleGroup: 'בטן',
      instructions:
      'לשכב על הגב, לכופף ברכיים ולהרים את השכמות מהקרקע.',
    ),
    const Exercise(
      id: 9,
      name: 'משיכת פולי עליון',
      category: 'גב',
      muscleGroup: 'גב ויד קדמית',
      instructions:
      'למשוך את המוט לכיוון החזה העליון תוך שמירה על חזה פתוח.',
    ),
    const Exercise(
      id: 10,
      name: 'חתירה',
      category: 'גב',
      muscleGroup: 'גב אמצעי',
      instructions:
      'למשוך את הידיות או המוט לכיוון הגוף תוך קירוב השכמות.',
    ),
    const Exercise(
      id: 11,
      name: 'לחיצת כתפיים',
      category: 'כתפיים',
      muscleGroup: 'כתפיים',
      instructions:
      'לדחוף את המשקולות מעל הראש ולרדת בשליטה לגובה הכתפיים.',
    ),
    const Exercise(
      id: 12,
      name: 'הרחקת כתפיים',
      category: 'כתפיים',
      muscleGroup: 'כתף צדית',
      instructions:
      'להרים את הידיים לצדדים עד גובה כתף עם מרפק מעט כפוף.',
    ),
    const Exercise(
      id: 13,
      name: 'כפיפת מרפקים',
      category: 'ידיים',
      muscleGroup: 'יד קדמית',
      instructions:
      'להחזיק משקולות בצידי הגוף, לכופף מרפקים ולהרים לכיוון הכתפיים.',
    ),
    const Exercise(
      id: 14,
      name: 'פשיטת מרפקים',
      category: 'ידיים',
      muscleGroup: 'יד אחורית',
      instructions:
      'להחזיק משקולת מעל הראש או לעבוד עם כבל, וליישר את המרפקים.',
    ),
    const Exercise(
      id: 15,
      name: 'עליות מדרגה',
      category: 'רגליים',
      muscleGroup: 'רגליים וישבן',
      instructions:
      'לעלות על מדרגה או ספסל עם רגל אחת ולרדת חזרה בשליטה.',
    ),
  ];

  static Exercise? getById(int id) {
    try {
      return exercises.firstWhere((exercise) => exercise.id == id);
    } catch (_) {
      return null;
    }
  }
}