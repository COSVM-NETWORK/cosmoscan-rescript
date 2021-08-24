@react.component
let make = () =>
  <ApolloClient.React.ApolloProvider client=Apollo.client>
    <TimeContext>
      <ThemeContext>
        <ModalContext> <Example /> <ExampleRoute /> <Modal /> </ModalContext>
      </ThemeContext>
    </TimeContext>
  </ApolloClient.React.ApolloProvider>
