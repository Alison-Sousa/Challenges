import streamlit as st
import pandas as pd
import numpy as np
import yfinance as yf
import plotly.express as px
from datetime import datetime
from streamlit_extras.metric_cards import style_metric_cards
from streamlit_extras.grid import grid

def build_sidebar():
    st.title("Select Companies")
    
    ticker_list = pd.read_csv("tickers.csv", header=None)  # Sem cabeçalho
    options = ticker_list.iloc[:, 1].tolist()  # Segunda coluna com os tickers
    options = [t for t in options if t != '0']  # Remove '0' da lista

    tickers = st.multiselect(label="Select Companies", options=options, placeholder='Codes')
    tickers = [t + ".SA" for t in tickers]  # Adiciona a extensão .SA apenas para os tickers selecionados

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

            prices.columns = prices.columns.str.rstrip(".SA")
            prices = prices.rename(columns={"^BVSP": "IBOVESPA"})
            
            return tickers, prices
        
        except Exception as e:
            st.error(f"Erro ao baixar dados: {str(e)}")
            return None, None

    return None, None

def build_main(tickers, prices):
    weights = np.ones(len(tickers)) / len(tickers)
    prices['portfolio'] = prices.drop('IBOVESPA', axis=1) @ weights
    norm_prices = 100 * prices / prices.iloc[0]
    returns = prices.pct_change()[1:]
    vols = returns.std() * np.sqrt(252)
    rets = (norm_prices.iloc[-1] - 100) / 100

    mygrid = grid(5, 5, 5, 5, 5, 5, vertical_align="top")
    for ticker in prices.columns:
        c = mygrid.container(border=True)
        c.subheader(ticker, divider="red")
        colA, colB, colC = c.columns(3)

        ticker_clean = ticker.rstrip('.SA')  # Remove a extensão .SA
        logo_url = None

        if ticker_clean == "IBOVESPA":
            logo_url = "https://upload.wikimedia.org/wikipedia/commons/8/8d/B3_logo_Brasil.png"  # Logo da B3
        elif ticker_clean == "portfolio":
            logo_url = "https://www.iconpacks.net/icons/2/free-portfolio-icon-2427-thumb.png"  # Ícone de portfólio
        else:
            stock_info = yf.Ticker(ticker_clean).info
            logo_url = stock_info.get('logo_url', None)
            if not logo_url:
                logo_url = f'https://raw.githubusercontent.com/thefintz/icones-b3/main/icones/{ticker_clean}.png'  # Imagem padrão

        if logo_url:
            colA.image(logo_url, width=50)  # Exibe o logotipo
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

st.set_page_config(layout="wide")

with st.sidebar:
    tickers, prices = build_sidebar()

st.title('Python for Investors')
if tickers:
    build_main(tickers, prices)
