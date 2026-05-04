from flask_wtf import FlaskForm
from wtforms import StringField, TextAreaField, SelectField, FileField, SubmitField
from wtforms.validators import DataRequired, Length, Optional

class ReportForm(FlaskForm):
    title = StringField('Problem Title', validators=[DataRequired(), Length(max=200)])
    description = TextAreaField('Description', validators=[DataRequired()])
    category = SelectField('Category', coerce=int, validators=[DataRequired()])
    location = StringField('Location', validators=[DataRequired(), Length(max=200)])
    reporter_email = StringField('Your Email (optional)', validators=[Optional(), Length(max=150)])
    image = FileField('Upload Photo')
    submit = SubmitField('Submit Report')

class TrackForm(FlaskForm):
    code = StringField('Tracking Code', validators=[DataRequired(), Length(min=8, max=20)])
    submit = SubmitField('Track Problem')