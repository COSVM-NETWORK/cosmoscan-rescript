type field_t =
  | Value(string)
  | Values(array<string>)
  | DataSource(ID.DataSource.t, string)
  | Block(ID.Block.t)
  | TxHash(Hash.t)
  | Validator(ValidatorSub.Mini.t)

module Styles = {
  open CssJs
  let tabletContainer = (theme: Theme.t) =>
    style(. [
      padding2(~v=#px(8), ~h=#px(24)),
      backgroundColor(theme.secondaryTableBg),
      borderRadius(px(8)),
      Media.mobile([padding2(~v=#px(8), ~h=#px(12))]),
    ])

  let tableSpacing = style(. [
    padding2(~v=#px(8), ~h=zero),
    Media.mobile([padding2(~v=#px(4), ~h=zero)]),
  ])

  let valueContainer = mw =>
    style(. [
      maxWidth(px(mw)),
      minHeight(px(20)),
      display(#flex),
      flexDirection(row),
      alignItems(center),
    ])
}

let renderField = (field, maxWidth) => {
  switch field {
  | Value(v) =>
    <div className={Styles.valueContainer(maxWidth)}>
      <Text value=v nowrap=true ellipsis=true block=true />
    </div>
  | Values(vals) =>
    <div className={CssHelper.flexBox(~direction=#column, ())}>
      {vals
      ->Belt.Array.mapWithIndex((i, v) =>
        <div key={i->string_of_int ++ v} className={Styles.valueContainer(maxWidth)}>
          <Text value=v nowrap=true ellipsis=true block=true align=Text.Right />
        </div>
      )
      ->React.array}
    </div>
  | DataSource(id, name) =>
    <div className={Styles.valueContainer(maxWidth)}>
      <TypeID.DataSource id position=TypeID.Mini />
      <HSpacing size=Spacing.sm />
      <Text
        value=name weight=Text.Regular spacing={Text.Em(0.02)} size=Text.Sm height={Text.Px(16)}
      />
    </div>
  | Block(id) =>
    <div className={Styles.valueContainer(maxWidth)}>
      <TypeID.Block id position=TypeID.Mini />
    </div>
  | TxHash(txHash) =>
    <div className={Styles.valueContainer(maxWidth)}>
      <TxLink txHash width=maxWidth size=Text.Sm />
    </div>
  | Validator(validator) =>
    <div className={Styles.valueContainer(maxWidth)}>
      <ValidatorMonikerLink
        size=Text.Sm
        validatorAddress={validator.operatorAddress}
        width={#px(maxWidth)}
        moniker={validator.moniker}
        identity={validator.identity}
      />
    </div>
  }
}

@react.component
let make = (~headers=["Key", "Value"], ~rows) => {
  let columnSize = headers |> Belt.Array.length > 2 ? Col.Four : Col.Six
  let valueWidth = Media.isMobile() ? 70 : 480

  let ({ThemeContext.theme: theme}, _) = React.useContext(ThemeContext.context)

  <div className={Styles.tabletContainer(theme)}>
    <div className=Styles.tableSpacing>
      <Row>
        {headers
        ->Belt.Array.mapWithIndex((i, header) => {
          <Col key={header ++ (i |> string_of_int)} col=columnSize colSm=columnSize>
            <Text value=header weight=Text.Semibold height={Text.Px(18)} transform=Text.Uppercase />
          </Col>
        })
        ->React.array}
      </Row>
    </div>
    <SeperatedLine mt=10 mb=15 />
    {rows
    ->Belt.Array.mapWithIndex((i, row) => {
      <div
        key={"outerRow" ++ (i |> string_of_int)} className={CssJs.merge(. [Styles.tableSpacing])}>
        <Row>
          {row
          ->Belt.Array.mapWithIndex((j, value) => {
            <Col key={"innerRow" ++ (j |> string_of_int)} col=columnSize colSm=columnSize>
              {renderField(value, valueWidth)}
            </Col>
          })
          ->React.array}
        </Row>
      </div>
    })
    ->React.array}
  </div>
}