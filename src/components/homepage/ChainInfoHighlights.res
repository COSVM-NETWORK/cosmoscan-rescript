module Styles = {
  open CssJs

  let card =
    style(. [
      position(#relative),
      Media.smallMobile([margin2(~v=#zero, ~h=#px(-5))]),
    ]);

  let innerCard =
    style(. [
      position(#relative),
      zIndex(2),
      minHeight(#px(152)),
      padding2(~v=#px(24), ~h=#px(32)),
      Media.mobile([padding2(~v=#px(10), ~h=#px(12)), minHeight(#px(146))]),
    ]);

  let fullWidth = style(. [width(#percent(100.))]);

  let specialBg =
    style(. [
      backgroundImage(
        #linearGradient((
          #deg(270.),
          list{(#percent(0.), hex("58595B")), (#percent(100.), hex("231F20"))},
        )),
      ),
    ]);

  let bandToken =
    style(. [position(#absolute), width(#percent(60.)), top(#percent(-40.)), right(#zero)]);
  
  let longCard = 
    style(. [
      width(#percent(100.)),
      marginTop(#px(24)),
      padding2(~v=#px(4), ~h=#px(24)),
    ]);

  let innerLongCard =
    style(. [
      minHeight(#px(106)),
      padding2(~v=#px(24), ~h=#px(12)),
      Media.mobile([padding2(~v=#px(10), ~h=#px(12)), minHeight(#px(50))]),
    ]);

  let halfWidth =
    style(. [
      width(#calc((#sub, #percent(50.), #px(17)))),
      Media.mobile([width(#percent(100.))]),
    ]);

  let mr2 =
    style(. [
      marginRight(#px(16)),
    ]);

  let pb = 
    style(. [
      Media.mobile([paddingBottom(#px(4))]),
    ]);
  };

module HighlightCard = {
  @react.component
  let make =
      (~label, ~valueAndExtraComponentSub: option<_>, ~special=false) => {
    let ({ThemeContext.theme: theme, isDarkMode}, _) = React.useContext(ThemeContext.context)
    let isMobile = Media.isMobile();

    <div className={Css.merge(list{Styles.card, special ? Styles.specialBg : "",CommonStyles.card(theme,isDarkMode)})}>
      {special && !isMobile
         ? <img alt="Band Token" src=Images.bandToken className=Styles.bandToken /> : React.null}
      <div
        id={"highlight-" ++ label}
        className={Css.merge(list{
          Styles.innerCard,
          CssHelper.flexBox(~direction=#column, ~justify=#spaceBetween, ~align=#flexStart, ()),
        })}>
        {switch (valueAndExtraComponentSub) {
         | Some((valueComponent, extraComponent)) =>
           <> <Text value=label size=Text.Xl weight=Text.Regular /> valueComponent extraComponent </>
         | None =>
           <>
             <LoadingCensorBar width=90 height=18 />
             <LoadingCensorBar width=120 height=20 />
             <LoadingCensorBar width=75 height=15 />
           </>
         }}
      </div>
    </div>;
  };
};

let getPrevDay = _ => {
  MomentRe.momentNow()
  |> MomentRe.Moment.defaultUtc
  |> MomentRe.Moment.subtract(~duration=MomentRe.duration(1., #days))
  |> MomentRe.Moment.format(Config.timestampUseFormat);
};

let getUnixTime = _ => {
  MomentRe.momentNow()
  |> MomentRe.Moment.defaultUtc
  |> MomentRe.Moment.subtract(~duration=MomentRe.duration(1., #days))
  |> MomentRe.Moment.toUnix;
};

@react.component
let make = (~latestBlockSub: Sub.variant<BlockSub.t>) => {
  let isMobile = Media.isMobile();
  let currentTime =
    React.useContext(TimeContext.context) |> MomentRe.Moment.format(Config.timestampUseFormat);
  let (prevDayTime, setPrevDayTime) = React.useState(getPrevDay);
  let (prevUnixTime, setPrevUnixTime) = React.useState(getUnixTime);

  let infoSub = React.useContext(GlobalContext.context);
  let ({ThemeContext.theme: theme, isDarkMode}, _) = React.useContext(ThemeContext.context);

  let activeValidatorCountSub = ValidatorSub.countByActive(true);
  let bondedTokenCountSub = ValidatorSub.getTotalBondedAmount();
  let latestTxsSub = TxSub.getList(~pageSize=1, ~page=1);
  let last24txsCountSub = TxQuery.countOffset(~timestamp=prevDayTime);
  let latestRequestSub = RequestSub.getList(~pageSize=1, ~page=1);
  let last24RequestCountSub = RequestQuery.countOffset(~timestamp=prevUnixTime);
  let latestBlock = BlockSub.getLatest();
  let avgBlockTimeSub = BlockSub.getAvgBlockTime(prevDayTime, currentTime);
  let avgCommissionSub = ValidatorSub.avgCommission(~isActive=true, ());
  
  let validatorInfoSub = Sub.all3(activeValidatorCountSub, bondedTokenCountSub, avgBlockTimeSub);
  let infoBondSub = Sub.all2(infoSub, bondedTokenCountSub);

  React.useEffect0(() => {
    let timeOutID = Js.Global.setInterval(() => {
      setPrevDayTime(getPrevDay)
      setPrevUnixTime(getUnixTime)
    }, 600_000);
    Some(() => {Js.Global.clearInterval(timeOutID)});
  });

  <>
    <Row justify=Row.Between>
      <Col col=Col.Three colSm=Col.Six mbSm=16>
        <HighlightCard
          label="BAND Price"
          special=true
          valueAndExtraComponentSub={
            switch (infoSub) {
            | Data({financial}) => Some(
              {
                let bandPriceInUSD = "$" ++ (financial.usdPrice |> Format.fPretty(~digits=2));
                <div className=CssHelper.flexBox()>
                  <div className=Styles.mr2>
                    <Text 
                      value=bandPriceInUSD
                      size=Text.Xxxl 
                      weight=Text.Bold 
                      color=theme.white
                    />
                  </div>
                  <Text 
                    value={
                      (financial.usd24HrChange > 0. ? "+" : "") 
                      ++ (financial.usd24HrChange |> Format.fPretty(~digits=2)) 
                      ++ "%"
                    }
                    size=Text.Body2
                    weight=Text.Regular 
                    color=(financial.usd24HrChange > 0. ? theme.success_600 : theme.error_600)
                  />
                </div>
              },
              {
                let bandPriceInBTC = financial.btcPrice;

                <div
                  className={Css.merge(list{
                    CssHelper.flexBox(~justify=#spaceBetween, ()),
                    Styles.fullWidth,
                  })}>
                  <Text value={bandPriceInBTC->Format.fPretty ++ " BTC"} />
                </div>;
              },
            )
            | _ => None
            }
          }
        />
      </Col>
      <Col col=Col.Three colSm=Col.Six mbSm=16>
        <HighlightCard
          label="Market Cap"
          valueAndExtraComponentSub={
            switch (infoSub) {
            | Data({financial}) => Some(
              {
                <Text
                  value={"$" ++ (financial.usdMarketCap |> Format.fCurrency)}
                  size=Text.Xxxl
                  color={theme.neutral_900}
                  weight=Text.Semibold
                />;
              },
              {
                let marketcap = financial.btcMarketCap;
                <Text value={(marketcap |> Format.fPretty) ++ " BTC"} />;
              },
            )
            | _ => None
          }
        }
        />
      </Col>
      <Col col=Col.Three colSm=Col.Six>
        <HighlightCard
          label="Latest Block"
          valueAndExtraComponentSub={
            switch (latestBlockSub) {
            | Data({height, validator: {moniker, identity, operatorAddress}}) => Some(
              <TypeID.Block id=height position=TypeID.Landing weight=Text.Semibold />,
              <ValidatorMonikerLink
                validatorAddress=operatorAddress
                moniker
                identity
                width={#percent(100.)}
                avatarWidth=20
              />,
            )
            | _ => None
          }
          }
        />
      </Col>
      <Col col=Col.Three colSm=Col.Six>
        <HighlightCard
          label="Active Validators"
          valueAndExtraComponentSub={
            switch (validatorInfoSub) {
            | Data(activeValidatorCount, _, avgBlockTime) => Some(
              {
                let activeValidators = activeValidatorCount->Format.iPretty;
                <Text
                  value=activeValidators
                  size=Text.Xxxl
                  color={theme.primary_600}
                  weight=Text.Semibold
                />
              },
              <Text
                value={"block time " ++ (avgBlockTime |> Format.fPretty(~digits=2)) ++ " secs"}
                size=Text.Body1 
                weight=Text.Regular 
              />
            )
            | _ => None
            }
          }
        />
      </Col>
    </Row>
    <div className={Css.merge(list{CssHelper.flexBox(), Styles.longCard, CommonStyles.card(theme, isDarkMode)})}>
      <div className=Styles.halfWidth>
        <Row justify=Row.Between >
            <Col col=Col.Six colSm=Col.Twelve>
              <div
                className={Css.merge(list{
                  Styles.innerLongCard,
                  CssHelper.flexBox(~direction=#column, ~justify=#spaceBetween, ~align=#flexStart, ()),
                })}>
                  <div className=Styles.pb>
                    <Text value="Total Transactions" size=Text.Body1 weight=Text.Regular />
                  </div>
                  <div className=CssHelper.flexBox()>
                    {switch (latestTxsSub) {
                    | Data((latestTx)) =>
                      <div className=Styles.mr2>
                        <Text 
                          value={
                            latestTx
                            ->Belt.Array.get(0)
                            ->Belt.Option.mapWithDefault(0, ({id}) => id )
                            ->float_of_int
                            ->Format.fCurrency
                          }
                          size=Text.Xxl 
                          weight=Text.Bold 
                          height={Text.Px(20)}
                          color=theme.neutral_900
                        />
                      </div>
                    | _ =>
                      <LoadingCensorBar width=90 height=18 />
                    }}
                    {switch (last24txsCountSub) {
                    | Data((last24Tx)) =>
                      <div className=Styles.mr2>
                        <Text 
                          value={"( " ++ (last24Tx |> float_of_int |> Format.fCurrency ) ++ " last 24 hr)"}
                          size=Text.Body2 
                          weight=Text.Regular 
                          color=theme.neutral_900
                        />
                      </div>
                    | _ =>
                      <LoadingCensorBar width=120 height=20 />
                    }}
                  </div>
              </div>
            </Col>
            <Col col=Col.Six colSm=Col.Twelve>
              <div
                className={Css.merge(list{
                  Styles.innerLongCard,
                  CssHelper.flexBox(~direction=#column, ~justify=#spaceBetween, ~align=#flexStart, ()),
                })}>
                  <div className=Styles.pb>
                    <Text value="Total Requests" size=Text.Body1 weight=Text.Regular />
                  </div>
                  <div className=CssHelper.flexBox()>
                    {switch (latestRequestSub) {
                    | Data((latestRequest)) =>
                      <div className=Styles.mr2>
                        <Text 
                          value={
                            latestRequest
                            ->Belt.Array.get(0)
                            ->Belt.Option.mapWithDefault(0, ({id}) => id |> ID.Request.toInt)
                            ->float_of_int
                            ->Format.fCurrency
                          }
                          size=Text.Xxl 
                          weight=Text.Bold 
                          height={Text.Px(20)}
                          color=theme.neutral_900
                        />
                      </div>
                    | _ =>
                      <LoadingCensorBar width=90 height=18 />
                    }}
                    {switch (last24RequestCountSub) {
                    | Data((last24Request)) =>
                      <div className=Styles.mr2>
                        <Text 
                          value={"( " ++ (last24Request |> float_of_int |> Format.fCurrency ) ++ " last 24 hr)"}
                          size=Text.Body2 
                          weight=Text.Regular 
                          color=theme.neutral_900
                        />
                      </div>
                    | _ =>
                      <LoadingCensorBar width=120 height=20 />
                    }}
                  </div>
              </div>
            </Col>
        </Row>
      </div>
      {isMobile ? React.null : <Divider ml=16 mr=16 h=58 />}
      <div className=Styles.halfWidth>
        <Row justify=Row.Between >
          <Col col=Col.Three colSm=Col.Twelve>
            <div
              className={Css.merge(list{
                Styles.innerLongCard,
                CssHelper.flexBox(~direction=#column, ~justify=#spaceBetween, ~align=#flexStart, ()),
              })}>
              {switch (latestBlock) {
              | Data({inflation}) =>
                <>
                  <div className=Styles.pb>
                    <Text value="Inflation Rate" size=Text.Body1 weight=Text.Regular />
                  </div>
                  <Text 
                     value={(inflation *. 100. |> Format.fPretty(~digits=2)) ++ "%"}
                    size=Text.Xxl 
                    weight=Text.Bold 
                    height={Text.Px(20)}
                    color=theme.neutral_900
                  />
                </>
              | _ =>
                <>
                  <LoadingCensorBar width=90 height=18 />
                  <LoadingCensorBar width=120 height=20 />
                </>
              }}
            </div>
          </Col>
          <Col col=Col.Three colSm=Col.Twelve>
            <div
              className={Css.merge(list{
                Styles.innerLongCard,
                CssHelper.flexBox(~direction=#column, ~justify=#spaceBetween, ~align=#flexStart, ()),
              })}>
              {switch (avgCommissionSub) {
              | Data(avgCommission) =>
                <>
                  <div className=Styles.pb>
                    <Text value="Staking APR" size=Text.Body1 weight=Text.Regular />
                  </div>
                  <Text 
                    value={(avgCommission |> Format.fPretty(~digits=2)) ++ "%"} 
                    size=Text.Xxl 
                    weight=Text.Bold 
                      height={Text.Px(20)}
                    color=theme.neutral_900
                  />
                </>
              | _ =>
                <>
                  <LoadingCensorBar width=90 height=18 />
                  <LoadingCensorBar width=120 height=20 />
                </>
              }}
            </div>
          </Col>
          <Col col=Col.Six colSm=Col.Twelve>
            <div
              className={Css.merge(list{
                Styles.innerLongCard,
                CssHelper.flexBox(~direction=#column, ~justify=#spaceBetween, ~align=#flexStart, ()),
              })}>
              {switch (infoBondSub) {
              | Data({financial},bondedTokenCount) =>
                <>
                  <div className=Styles.pb>
                    <Text value="BAND Bonded" size=Text.Body1 weight=Text.Regular />
                  </div>
                  <div className=CssHelper.flexBox()>
                    <div className=Styles.mr2>
                      <Text 
                        value={
                          (
                            ((bondedTokenCount |> Coin.getBandAmountFromCoin) /. financial.circulatingSupply *. 100.) 
                            |> Format.fPretty(~digits=2)
                          )
                          ++ "%"
                        }
                        size=Text.Xxl 
                        weight=Text.Bold 
                        color=theme.neutral_900
                      />
                    </div>
                    <Text 
                      value={
                        (bondedTokenCount |> Coin.getBandAmountFromCoin |> Format.fCurrency)
                        ++ "/" ++ (financial.circulatingSupply |> Format.fCurrency)
                        ++ " BAND"
                      }
                      size=Text.Body2 
                      weight=Text.Regular 
                      height={Text.Px(20)}
                      color=theme.neutral_900
                    />
                  </div>
                </>
              | _ =>
                <>
                  <LoadingCensorBar width=90 height=18 />
                  <LoadingCensorBar width=120 height=20 />
                </>
              }}
            </div>
          </Col>
        </Row>
      </div>
    </div>
  </>
};
