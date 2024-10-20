import streamlit as st
import pandas as pd
import numpy as np
import yfinance as yf
import plotly.express as px
from datetime import datetime
import requests
from streamlit_extras.metric_cards import style_metric_cards
from streamlit_extras.grid import grid

# Configuração da página deve ser a primeira coisa a ser chamada
st.set_page_config(layout="wide")

# Title of the application
st.title("Investment Analysis")

# Add the itau.svg image in the sidebar
st.sidebar.image("itau.svg", use_column_width=True)

@st.cache_data
def get_tickers():
    """Get the list of tickers from the CSV file."""
    ticker_list = pd.read_csv("tickers.csv", header=None)  # No header
    options = ticker_list.iloc[:, 1].tolist()  # The second column contains the tickers (ignores index 0)
    options = [t for t in options if t != '0']  # Remove '0' from the list
    return options

def build_sidebar():
    options = get_tickers()  # Fetch the tickers
    st.title("Select Companies")

    tickers = st.multiselect(label="Select Companies", options=options, placeholder='Codes')
    tickers = [t + ".SA" for t in tickers]  # Append the .SA suffix only for selected tickers

    start_date = st.date_input("From", format="DD/MM/YYYY", value=datetime(2023, 1, 2))
    end_date = st.date_input("To", format="DD/MM/YYYY", value="today")

    if tickers:
        try:
            prices = yf.download(tickers + ["^BVSP"], start=start_date, end=end_date)["Adj Close"]
            
            if prices.empty:
                st.error("Não foram encontrados dados para os tickers selecionados.")
                return None, None
            
            if len(tickers) == 1:
                prices = prices.to_frame()
                prices.columns = [tickers[0].rstrip(".SA")]
            
            return tickers, prices
        
        except Exception as e:
            st.error(f"Erro ao baixar dados: {str(e)}")
            return None, None

    return None, None

def build_main(tickers, prices):
    index_col = prices.columns[-1]  # Remove a referência ao IBOVESPA

    weights = np.ones(len(tickers)) / len(tickers)
    prices['portfolio'] = prices.drop(index_col, axis=1) @ weights
    norm_prices = 100 * prices / prices.iloc[0]
    returns = prices.pct_change()[1:]
    vols = returns.std() * np.sqrt(252)
    rets = (norm_prices.iloc[-1] - 100) / 100

    mygrid = grid(5, 5, 5, 5, 5, 5, vertical_align="top")
    for ticker in prices.columns:
        c = mygrid.container(border=True)
        c.subheader(ticker, divider="red")
        colA, colB, colC = c.columns(3)

        # Define logo URL com condições
        ticker_clean = ticker.rstrip('.SA')  # Remove a extensão .SA
        logo_url = None

        if ticker == "^BVSP":
            logo_url = "bov.png"  # Logo da B3 para IBOVESPA
        elif ticker == "portfolio":
            logo_url = "chart.svg"  # Ícone de portfólio
        else:
            stock_info = yf.Ticker(ticker_clean).info
            logo_url = stock_info.get('logo_url', None)
            if not logo_url:
                logo_url = f'https://raw.githubusercontent.com/thefintz/icones-b3/main/icones/{ticker_clean}.png'  # Imagem padrão

        if logo_url:
            colA.image(logo_url, width=100)  # Ajustei a largura da imagem para 100
        else:
            colA.write("🔍 Logo não disponível")

        colA.write(f"🏢 {ticker_clean}")

        colB.metric(label="Return", value=f"{rets[ticker]:.0%}")
        colC.metric(label="Volatility", value=f"{vols[ticker]:.0%}")
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

with st.sidebar:
    tickers, prices = build_sidebar()

if tickers:
    build_main(tickers, prices)
