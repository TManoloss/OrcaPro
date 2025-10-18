import os
import pickle
import re
from typing import Dict, List, Tuple
import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.naive_bayes import MultinomialNB
from sklearn.pipeline import Pipeline
import joblib

class TransactionCategorizer:
    """
    Categorizador de transações usando Machine Learning.
    Usa TF-IDF + Naive Bayes para classificação de texto.
    """
    
    # Categorias padrão
    CATEGORIES = [
        'Alimentação',
        'Transporte',
        'Moradia',
        'Saúde',
        'Educação',
        'Lazer',
        'Compras',
        'Serviços',
        'Investimentos',
        'Salário',
        'Outros'
    ]
    
    # Palavras-chave para categorização baseada em regras (fallback)
    KEYWORDS_MAP = {
        'Alimentação': [
            'restaurante', 'lanche', 'comida', 'mercado', 'supermercado',
            'padaria', 'açougue', 'feira', 'delivery', 'ifood', 'uber eats',
            'rappi', 'pizza', 'hamburguer', 'café', 'bar', 'jantar', 'almoço'
        ],
        'Transporte': [
            'uber', 'taxi', 'combustivel', 'gasolina', 'etanol', 'onibus',
            'metrô', 'estacionamento', 'pedágio', 'moto', 'carro', '99',
            'transporte', 'passagem'
        ],
        'Moradia': [
            'aluguel', 'condominio', 'iptu', 'luz', 'água', 'gas',
            'internet', 'telefone', 'móveis', 'reforma', 'manutenção'
        ],
        'Saúde': [
            'farmácia', 'remédio', 'médico', 'consulta', 'exame',
            'hospital', 'plano de saúde', 'dentista', 'terapia'
        ],
        'Educação': [
            'escola', 'faculdade', 'curso', 'livro', 'material escolar',
            'mensalidade', 'matrícula', 'apostila'
        ],
        'Lazer': [
            'cinema', 'teatro', 'show', 'viagem', 'hotel', 'passeio',
            'parque', 'netflix', 'spotify', 'streaming', 'academia',
            'esporte'
        ],
        'Compras': [
            'loja', 'roupa', 'calçado', 'eletrônico', 'shopping',
            'presente', 'magazine', 'varejista'
        ],
        'Serviços': [
            'cabeleireiro', 'barbeiro', 'manicure', 'lavanderia',
            'costureira', 'reparo', 'assistência'
        ],
        'Investimentos': [
            'aplicação', 'investimento', 'poupança', 'cdb', 'ações',
            'fundo', 'renda fixa'
        ],
        'Salário': [
            'salário', 'pagamento', 'vencimento', 'remuneração',
            'ordenado', 'salario'
        ]
    }
    
    def __init__(self):
        self.model = None
        self.last_confidence = 0.0
        self.model_path = os.getenv('MODEL_PATH', '/app/models/categorizer.pkl')
        self._ensure_model_dir()
    
    def _ensure_model_dir(self):
        """Garante que o diretório de modelos existe"""
        model_dir = os.path.dirname(self.model_path)
        if model_dir and not os.path.exists(model_dir):
            os.makedirs(model_dir, exist_ok=True)
    
    def load_model(self):
        """Carrega modelo treinado ou cria um novo"""
        if os.path.exists(self.model_path):
            try:
                self.model = joblib.load(self.model_path)
                print(f"Modelo carregado de {self.model_path}")
            except Exception as e:
                print(f"Erro ao carregar modelo: {e}")
                self._create_default_model()
        else:
            self._create_default_model()
    
    def _create_default_model(self):
        """Cria e treina modelo com dados sintéticos"""
        print("Criando modelo padrão com dados sintéticos...")
        
        # Dados de treinamento sintéticos
        training_data = self._generate_training_data()
        
        # Cria pipeline
        self.model = Pipeline([
            ('tfidf', TfidfVectorizer(
                max_features=1000,
                ngram_range=(1, 2),
                strip_accents='unicode',
                lowercase=True
            )),
            ('clf', MultinomialNB(alpha=0.1))
        ])
        
        # Treina
        X = [item['text'] for item in training_data]
        y = [item['category'] for item in training_data]
        
        self.model.fit(X, y)
        
        # Salva modelo
        try:
            joblib.dump(self.model, self.model_path)
            print(f"Modelo salvo em {self.model_path}")
        except Exception as e:
            print(f"Erro ao salvar modelo: {e}")
    
    def _generate_training_data(self) -> List[Dict]:
        """Gera dados de treinamento sintéticos"""
        training_data = []
        
        for category, keywords in self.KEYWORDS_MAP.items():
            for keyword in keywords:
                # Variações do keyword
                training_data.append({
                    'text': keyword,
                    'category': category
                })
                training_data.append({
                    'text': f"Pagamento {keyword}",
                    'category': category
                })
                training_data.append({
                    'text': f"Compra em {keyword}",
                    'category': category
                })
        
        return training_data
    
    def categorize(self, description: str, amount: float = 0.0, 
                   current_category: str = '') -> str:
        """
        Categoriza uma transação baseada na descrição.
        
        Args:
            description: Descrição da transação
            amount: Valor da transação (pode ajudar na categorização)
            current_category: Categoria atual (se houver)
        
        Returns:
            Categoria prevista
        """
        if not description:
            return 'Outros'
        
        # Normaliza descrição
        description_clean = self._preprocess_text(description)
        
        # Tenta categorização baseada em regras primeiro (fallback)
        rule_based_category = self._rule_based_categorization(description_clean)
        
        # Se temos modelo ML, usa ele
        if self.model:
            try:
                # Predição
                prediction = self.model.predict([description_clean])[0]
                
                # Confiança da predição
                probabilities = self.model.predict_proba([description_clean])[0]
                self.last_confidence = float(max(probabilities))
                
                # Se confiança é baixa, usa regra
                if self.last_confidence < 0.5 and rule_based_category:
                    return rule_based_category
                
                return prediction
                
            except Exception as e:
                print(f"Erro na predição ML: {e}")
                return rule_based_category if rule_based_category else 'Outros'
        
        # Fallback para regras
        return rule_based_category if rule_based_category else 'Outros'
    
    def _preprocess_text(self, text: str) -> str:
        """Pré-processa texto"""
        # Lowercase
        text = text.lower()
        
        # Remove caracteres especiais mantendo espaços
        text = re.sub(r'[^a-záàâãéèêíïóôõöúçñ\s]', '', text)
        
        # Remove espaços extras
        text = ' '.join(text.split())
        
        return text
    
    def _rule_based_categorization(self, text: str) -> str:
        """Categorização baseada em regras (keywords)"""
        text_lower = text.lower()
        
        # Conta matches por categoria
        category_scores = {}
        
        for category, keywords in self.KEYWORDS_MAP.items():
            score = 0
            for keyword in keywords:
                if keyword.lower() in text_lower:
                    score += 1
            
            if score > 0:
                category_scores[category] = score
        
        # Retorna categoria com maior score
        if category_scores:
            return max(category_scores.items(), key=lambda x: x[1])[0]
        
        return ''
    
    def retrain(self, transactions: List[Dict]):
        """
        Retreina o modelo com novas transações.
        
        Args:
            transactions: Lista de dicts com 'description' e 'category'
        """
        if not transactions:
            return
        
        X = [t['description'] for t in transactions]
        y = [t['category'] for t in transactions]
        
        if self.model:
            # Retreina modelo existente
            self.model.fit(X, y)
        else:
            # Cria novo modelo
            self._create_default_model()
            self.model.fit(X, y)
        
        # Salva modelo atualizado
        try:
            joblib.dump(self.model, self.model_path)
            print(f"Modelo retreinado e salvo em {self.model_path}")
        except Exception as e:
            print(f"Erro ao salvar modelo retreinado: {e}")
    
    def evaluate(self, test_data: List[Dict]) -> Dict:
        """
        Avalia o modelo com dados de teste.
        
        Args:
            test_data: Lista de dicts com 'description' e 'category'
        
        Returns:
            Dicionário com métricas de avaliação
        """
        if not self.model or not test_data:
            return {}
        
        X_test = [t['description'] for t in test_data]
        y_test = [t['category'] for t in test_data]
        
        predictions = self.model.predict(X_test)
        
        # Calcula acurácia
        correct = sum(1 for pred, true in zip(predictions, y_test) if pred == true)
        accuracy = correct / len(y_test) if y_test else 0
        
        return {
            'accuracy': accuracy,
            'total_samples': len(y_test),
            'correct_predictions': correct
        }