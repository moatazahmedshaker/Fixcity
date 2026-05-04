from app import create_app
from models import db, Category, Authority, Region, RoutingRule
import hashlib
app = create_app()
app.app_context().push()
db.create_all()

# seed categories
cats = ['Road','Garbage','Streetlight','Water Leak','Pollution','Other']
for c in cats:
    if not Category.query.filter_by(name=c).first():
        db.session.add(Category(name=c))

# seed regions
regions = ['Cairo','Giza','Alexandria','Beheira','Qalyubia']
for r in regions:
    if not Region.query.filter_by(name=r).first():
        db.session.add(Region(name=r))

# seed authorities with demo passwords (password: demo123)
def ph(p): return hashlib.sha256(p.encode()).hexdigest()
auths = [
    ('Ministry of Local Development','National','local@fixcity.eg', ph('demo123')),
    ('Cairo Public Works','Cairo','cairo@fixcity.eg', ph('demo123')),
    ('Giza Public Works','Giza','giza@fixcity.eg', ph('demo123')),
    ('Ministry of Environment','National','env@fixcity.eg', ph('demo123')),
]
for name, region, email, pw in auths:
    if not Authority.query.filter_by(email=email).first():
        db.session.add(Authority(name=name, region=region, email=email, password_hash=pw))

db.session.commit()

# routing rules: simple rules mapping category + region -> authority
def add_rule(cat, region, authority_email):
    auth = Authority.query.filter_by(email=authority_email).first()
    if auth and not RoutingRule.query.filter_by(category_name=cat, region_name=region).first():
        db.session.add(RoutingRule(category_name=cat, region_name=region, authority_id=auth.id))

add_rule('Road','Cairo','cairo@fixcity.eg')
add_rule('Garbage','Cairo','cairo@fixcity.eg')
add_rule('Road','Giza','giza@fixcity.eg')
add_rule('Garbage','Giza','giza@fixcity.eg')

db.session.commit()
print('Seeded demo authorities, regions, categories and routing rules.')