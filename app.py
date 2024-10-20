import streamlit as st
import pandas as pd
import numpy as np
import yfinance as yf
import plotly.express as px
from datetime import datetime
from streamlit_extras.metric_cards import style_metric_cards
from streamlit_extras.grid import grid

# Função para construir a barra lateral
def build_sidebar():
    ticker_list = pd.read_csv("tickers.csv", index_col=0)  # Alterado para tickers.csv
    tickers = st.multiselect(label="Selecione as Empresas", options=ticker_list['tickers'].tolist(), placeholder='Códigos')  # Corrigido para usar a coluna correta
    tickers = [t + ".SA" for t in tickers]
    start_date = st.date_input("De", format="DD/MM/YYYY", value=datetime(2023, 1, 2))
    end_date = st.date_input("Até", format="DD/MM/YYYY", value="today")

    if tickers:
        prices = yf.download(tickers, start=start_date, end=end_date)["Adj Close"]
        if len(tickers) == 1:
            prices = prices.to_frame()
            prices.columns = [tickers[0].rstrip(".SA")]
                    
        prices.columns = prices.columns.str.rstrip(".SA")
        prices['IBOV'] = yf.download("^BVSP", start=start_date, end=end_date)["Adj Close"]
        return tickers, prices
    return None, None

# Função para construir o conteúdo principal
def build_main(tickers, prices):
    weights = np.ones(len(tickers)) / len(tickers)
    prices['portfolio'] = prices.drop("IBOV", axis=1) @ weights
    norm_prices = 100 * prices / prices.iloc[0]
    returns = prices.pct_change()[1:]
    vols = returns.std() * np.sqrt(252)
    rets = (norm_prices.iloc[-1] - 100) / 100

    mygrid = grid(5, 5, 5, 5, 5, 5, vertical_align="top")
    for t in prices.columns:
        c = mygrid.container(border=True)
        c.subheader(t, divider="red")
        colA, colB, colC = c.columns(3)

        # Removendo imagens e usando texto
        if t == "portfolio":
            colA.write("📊 Portfolio")
        elif t == "IBOV":
            colA.write("📈 IBOV")
        else:
            colA.write(f"🏢 {t.rstrip('.SA')}")

        colB.metric(label="Retorno", value=f"{rets[t]:.0%}")
        colC.metric(label="Volatilidade", value=f"{vols[t]:.0%}")
        style_metric_cards(background_color='rgba(255,255,255,0)')

    col1, col2 = st.columns(2, gap='large')
    with col1:
        st.subheader("Desempenho Relativo")
        st.line_chart(norm_prices, height=600)

    with col2:
        st.subheader("Risco-Retorno")
        fig = px.scatter(
            x=vols,
            y=rets,
            text=vols.index,
            color=rets / vols,
            color_continuous_scale=px.colors.sequential.Bluered_r
        )
        fig.update_traces(
            textfont_color='white',
            marker=dict(size=45),
            textfont_size=10,
        )
        fig.layout.yaxis.title = 'Retorno Total'
        fig.layout.xaxis.title = 'Volatilidade (anualizada)'
        fig.layout.height = 600
        fig.layout.xaxis.tickformat = ".0%"
        fig.layout.yaxis.tickformat = ".0%"
        fig.layout.coloraxis.colorbar.title = 'Sharpe'
        st.plotly_chart(fig, use_container_width=True)

# Configuração da página
st.set_page_config(layout="wide")

# Barra lateral
with st.sidebar:
    tickers, prices = build_sidebar()

# Título da página principal
st.title('Python para Investidores')
if tickers:
    build_main(tickers, prices)
