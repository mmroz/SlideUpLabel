import Foundation

class AnimatedLabel: UIView {
	private static let animationDuration = 0.25
	
	private var labels = [UILabel]()
	
	var attributedText: NSAttributedString? {
		get { return nil }
		set {
			var singleGraphemeStrings: [NSAttributedString] = []
			
			// Split the text into single-grapheme cluster attributed strings.
			if let attributedText = newValue {
				attributedText.enumerateAttributes(
					in: NSRange(location: 0, length: attributedText.length),
					options: .longestEffectiveRangeNotRequired,
					using: { (attributes, range, _) in
						attributedText.string.enumerateSubstrings(
							in: Range(range, in: attributedText.string)!,
							options: .byComposedCharacterSequences) { (nextCharacter, _, _, _) in
								singleGraphemeStrings.append(NSAttributedString(string: nextCharacter!, attributes: attributes))
						}
					}
				)
			}
			
			let singleGraphemeStringLabels = singleGraphemeStrings.map { attributedString -> UILabel in
				let label = UILabel()
				label.attributedText = attributedString
				return label
			}
			
			// Remove old labels.
			for (index, currentLabel) in labels.enumerated() {
				var shouldAnimateRemoval = true
				if let newAttributedText = singleGraphemeStringLabels[bounded: index]?.attributedText {
					shouldAnimateRemoval = newAttributedText != currentLabel.attributedText
				}
				if shouldAnimateRemoval {
					UIView.transition(with: self, duration: Self.animationDuration, options: [.transitionCrossDissolve], animations: {
					  currentLabel.removeFromSuperview()
					}, completion: nil)
				} else {
					currentLabel.removeFromSuperview()
				}
			}
			
			// Install new labels in the correct positions, aligned on trailing edges.
			var previous: UILabel? = nil
			for (index, currentLabel) in singleGraphemeStringLabels.enumerated().reversed() {
				var shouldAnimateInstallation: Bool = true

				// The replacement need not be animated if the values are the same.
				if let existingAttributedText = labels[bounded: index]?.attributedText {
					shouldAnimateInstallation = (existingAttributedText != currentLabel.attributedText)
				}

				if shouldAnimateInstallation {
					let offset = Double.random(in: 0..<0.1) as CFTimeInterval
					let animationOffset = currentLabel.layer.convertTime(CACurrentMediaTime() + offset, from: nil)
					let animation = animateUp(layerTimeOffset: animationOffset)
					currentLabel.layer.add(animation, forKey: CATransitionType.push.rawValue)
				}

				addSubviewsForAutolayout(currentLabel)
				if let previous = previous {
					NSLayoutConstraint.activate([
						currentLabel.trailingAnchor.constraint(equalTo: previous.leadingAnchor),
						currentLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor)
					])
				} else {
					NSLayoutConstraint.activate([
						currentLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor),
						currentLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor)
					])
				}
				previous = currentLabel
			}
			self.labels = singleGraphemeStringLabels
		}
	}
	
	init() {
		super.init(frame: CGRect.zero)
		clipsToBounds = true
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("Not implemented")
	}
	
	private func animateUp(layerTimeOffset: CFTimeInterval) -> CATransition {
		let animation: CATransition = CATransition()
		animation.beginTime = layerTimeOffset
		animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
		animation.type = CATransitionType.push
		animation.subtype = CATransitionSubtype.fromTop
		animation.duration = Self.animationDuration
		animation.fillMode = .backwards
		return animation
	}
}

