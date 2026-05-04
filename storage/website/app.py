import os
import random
import string
from flask import Flask, render_template, request, redirect, url_for, flash, send_from_directory
from werkzeug.utils import secure_filename

# Import database
from models import db, Category, Problem, StatusUpdate
from forms import ReportForm, TrackForm

# Create Flask app
app = Flask(__name__)

# SIMPLE CONFIG
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///fixcity.db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['SECRET_KEY'] = 'dev-key-123'
app.config['UPLOAD_FOLDER'] = 'uploads'

# Initialize database
db.init_app(app)

# FORCE DATABASE RECREATION
with app.app_context():
    # Drop all tables and recreate
    print("Dropping all tables")
    db.drop_all()
    print("Creating fresh database")
    db.create_all()
    print("Database created from scratch")
    
    # Add sample categories
    categories = [
        Category(name='Pothole'),
        Category(name='Trash'),
        Category(name='Street Lighting'),
        Category(name='Other')
    ]
    db.session.add_all(categories)
    db.session.commit()
    print("Sample categories added")

# Create uploads folder
os.makedirs('uploads', exist_ok=True)

def random_code(n=8):
    return ''.join(random.choices(string.ascii_uppercase + string.digits, k=n))

# ROUTES

@app.route('/')
def index():
    categories = Category.query.all()
    return render_template('index.html', categories=categories)

@app.route('/report', methods=['GET', 'POST'])
def report():
    form = ReportForm()
    form.category.choices = [(c.id, c.name) for c in Category.query.all()]
    
    if form.validate_on_submit():
        # Handle file upload
        filename = None
        if form.image.data and form.image.data.filename:
            file = form.image.data
            filename = secure_filename(file.filename)
            file.save(os.path.join(app.config['UPLOAD_FOLDER'], filename))

        # Generate unique tracking code
        code = random_code(10)
        while Problem.query.filter_by(tracking_code=code).first():
            code = random_code(10)

        # Create problem record
        problem = Problem(
            tracking_code=code,
            title=form.title.data,
            description=form.description.data,
            category_id=form.category.data,
            location=form.location.data,
            reporter_email=form.reporter_email.data,  # ⬅️ USING THE NEW FIELD
            image_filename=filename,
            status='new'
        )
        
        db.session.add(problem)
        db.session.commit()
        
        return render_template('thanks.html', code=code)
    
    return render_template('report.html', form=form)

@app.route('/track', methods=['GET', 'POST'])
def track():
    form = TrackForm()
    problem = None
    
    if form.validate_on_submit():
        code = form.code.data.strip().upper()
        problem = Problem.query.filter_by(tracking_code=code).first()
        if not problem:
            flash('Tracking code not found', 'danger')
            return render_template('track_form.html', form=form, problem=problem)
        else:
            return render_template('track.html', form=form, problem=problem)
    
    return render_template('track_form.html', form=form, problem=problem)

@app.route('/admin')
def admin_dashboard():
    problems = Problem.query.order_by(Problem.created_at.desc()).all()
    return render_template('admin_dashboard.html', problems=problems)

@app.route('/authority')
def authority_login():
    return render_template('authority_login.html')

@app.route('/authority/dashboard')
def authority_dashboard():
    return render_template('authority_dashboard.html')

@app.route('/admin/update_status/<int:problem_id>', methods=['POST'])
def update_status(problem_id):
    problem = Problem.query.get_or_404(problem_id)
    new_status = request.form.get('status')
    
    if new_status and new_status != problem.status:
        problem.status = new_status
        db.session.commit()
        flash('Status updated successfully', 'success')
    
    return redirect(url_for('admin_dashboard'))

@app.route('/uploads/<filename>')
def uploaded_file(filename):
    return send_from_directory(app.config['UPLOAD_FOLDER'], filename)

if __name__ == '__main__':
    print("FixCity with FRESH DATABASE Started!")
    print("Open: http://localhost:5000")
    app.run(debug=True, port=5000)

@app.route('/debug-static')
def debug_static():
    import os
    debug_info = {
        'current_directory': os.getcwd(),
        'static_folder_exists': os.path.exists('static'),
        'static_folder_contents': os.listdir('static') if os.path.exists('static') else 'FOLDER NOT FOUND',
        'css_folder_exists': os.path.exists('static/css') if os.path.exists('static') else False,
        'css_files': os.listdir('static/css') if os.path.exists('static/css') else 'CSS FOLDER NOT FOUND',
        'egypt_emblem_exists': os.path.exists('static/egypt_emblem.png') if os.path.exists('static') else False
    }
    return debug_info