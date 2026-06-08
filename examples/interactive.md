# Reinforcement Learning Reward Curves

Adjust the reward value to see how it affects the agent's learning curve.

@slider(param: "reward", min: 0.0, max: 1.0, value: 0.5)

@metric(label: "Reward", value: 0.5)

@chart(x_label: "Step", y_label: "Reward", width: 400, height: 200)

The chart shows cumulative reward over 100 training steps. Drag the slider
to explore different reward functions and observe how the learning curve changes.

:::callout(type: "tip", title: "Try this")
Move the slider all the way to 1.0 to see maximum reward, then drop it to 0.1
to see how the agent performs with sparse rewards.
:::
