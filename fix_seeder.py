import re

with open('lib/core/utils/firebase_seeder.dart', 'r', encoding='utf-8') as f:
    code = f.read()

replacement = '''
    final List<String> blackMenPics = [
      'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=400&q=80',
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&q=80',
      'https://images.unsplash.com/photo-1522529599102-193c0d76b5b6?w=400&q=80',
      'https://images.unsplash.com/photo-1531384441138-2736e62e0919?w=400&q=80',
      'https://images.unsplash.com/photo-1530268729831-4b0b9e170218?w=400&q=80',
      'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=400&q=80',
      'https://images.unsplash.com/photo-1528892952291-009c663ce843?w=400&q=80',
    ];

    final List<String> blackWomenPics = [
      'https://images.unsplash.com/photo-1531123897727-8f129e1bfa8ea?w=400&q=80',
      'https://images.unsplash.com/photo-1543269664-56d93c1b41a6?w=400&q=80',
      'https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?w=400&q=80',
      'https://images.unsplash.com/photo-1515023115689-589c33041d3c?w=400&q=80',
      'https://images.unsplash.com/photo-1563351672-62b74891a28a?w=400&q=80',
      'https://images.unsplash.com/photo-1531123414708-f47f29bb5b67?w=400&q=80',
      'https://images.unsplash.com/photo-1523825036634-aab3cce0691e?w=400&q=80',
    ];
    
    String profileImageURL = '';
    if (gender == 'men') {
      profileImageURL = blackMenPics[picId % blackMenPics.length];
    } else {
      profileImageURL = blackWomenPics[picId % blackWomenPics.length];
    }
'''

code = code.replace("final profileImageURL = 'https://randomuser.me/api/portraits/$gender/$picId.jpg';", replacement)

with open('lib/core/utils/firebase_seeder.dart', 'w', encoding='utf-8') as f:
    f.write(code)
