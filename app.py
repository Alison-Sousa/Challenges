import pandas as pd
import streamlit as st
import yfinance as yf
import numpy as np
import plotly.express as px
from datetime import datetime
from streamlit_extras.metric_cards import style_metric_cards
from streamlit_extras.grid import grid

# Função para construir a barra lateral
def build_sidebar():
    # Lê o CSV sem considerar cabeçalho
    ticker_list = pd.read_csv("tickers.csv", header=None)  # Lê o CSV sem cabeçalho
    tickers = st.multiselect(label="Select Companies", options=ticker_list[1].tolist(), placeholder='Codes')  # Usa a segunda coluna
    tickers = [t + ".SA" for t in tickers]
    start_date = st.date_input("From", format="DD/MM/YYYY", value=datetime(2023, 1, 2))
    end_date = st.date_input("To", format="DD/MM/YYYY", value="today")

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

        if t == "portfolio":
            colA.write("📊 Portfolio")
        elif t == "IBOV":
            colA.write("📈 IBOV")
        else:
            colA.write(f"🏢 {t.rstrip('.SA')}")

        colB.metric(label="Return", value=f"{rets[t]:.0%}")
        colC.metric(label="Volatility", value=f"{vols[t]:.0%}")
        style_metric_cards(background_color='rgba(255,255,255,0)')

    col1, col2 = st.columns(2, gap='large')
    with col1:
        st.subheader("Relative Performance")
        st.line_chart(norm_prices, height=600)

    with col2:
        st.subheader("Risk-Return")
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
        fig.layout.yaxis.title = 'Total Return'
        fig.layout.xaxis.title = 'Annualized Volatility'
        fig.layout.height = 600
        fig.layout.xaxis.tickformat = ".0%"
        fig.layout.yaxis.tickformat = ".0%"
        fig.layout.coloraxis.colorbar.title = 'Sharpe'
        st.plotly_chart(fig, use_container_width=True)

# Sidebar
with st.sidebar:
    st.title("Quant Challenge")
    tickers, prices = build_sidebar()

# Título da página principal
st.title('Python for Investors')

# Se houver tickers selecionados, exibe o painel
if tickers:
    build_main(tickers, prices)
