import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import OneHotEncoder
from sklearn.compose import ColumnTransformer
from sklearn.pipeline import Pipeline
from sklearn.metrics import classification_report, confusion_matrix, roc_auc_score
from sklearn.linear_model import LogisticRegression

# Load features
df = pd.read_csv('data/processed/customer_features.csv', parse_dates=['signup_date','last_purchase'])

target = 'churn_label'
numeric = ['age', 'recency_days', 'frequency', 'monetary', 'avg_basket', 'days_since_signup']
categorical = ['gender', 'region', 'state', 'income_band']

X = df[numeric + categorical]
y = df[target].astype(int)

pre = ColumnTransformer(
    transformers=[
        ('num', 'passthrough', numeric),
        ('cat', OneHotEncoder(handle_unknown='ignore'), categorical)
    ]
)

model = LogisticRegression(max_iter=400, class_weight='balanced')
pipe = Pipeline([('pre', pre), ('clf', model)])

X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, stratify=y, random_state=42)

pipe.fit(X_train, y_train)
pred = pipe.predict(X_test)
proba = pipe.predict_proba(X_test)[:,1]

print('AUC:', roc_auc_score(y_test, proba))
print(classification_report(y_test, pred))
print('Confusion Matrix:\n', confusion_matrix(y_test, pred))