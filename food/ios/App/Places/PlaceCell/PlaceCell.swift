import UIKit
import AlamofireImage

class PlaceCell: UICollectionViewCell {
  
  @IBOutlet weak var textLabel: UILabel!
  @IBOutlet weak var milesAwayLabel: UILabel!
  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var containerView: UIView!
  @IBOutlet weak var articleButton: UIButton!
  
  override func awakeFromNib() {
    super.awakeFromNib()
    containerView.layer.cornerRadius = 5.0
    containerView.layer.borderColor = UIColor.lightGray.cgColor
    containerView.layer.borderWidth = 1
    let radius = CGFloat(3)
    containerView.layer.shadowOffset = CGSize(width: radius, height: -radius)
    containerView.layer.shadowRadius = radius

    imageView.layer.cornerRadius = 5.0
    imageView.clipsToBounds = true
    imageView.layer.addSublayer(self.gradientLayer(bounds: self.imageView.bounds))

  }

  func gradientLayer(bounds: CGRect) -> CAGradientLayer {
    let transparent = UIColor.black.withAlphaComponent(0.0).cgColor
    let opaque = UIColor.black.withAlphaComponent(1.0).cgColor
    let gradient = CAGradientLayer()
    gradient.frame = bounds
    gradient.colors = [opaque, transparent, transparent, transparent]
    return gradient
  }

  
  func attributedText(text: String, font: UIFont) -> NSMutableAttributedString {
    let attributedString = NSMutableAttributedString(string: text)
    let paragraphStyle = NSMutableParagraphStyle()
    
    // *** set LineSpacing property in points ***
    paragraphStyle.lineSpacing = 5 // Whatever line spacing you want in points
    
    // *** Apply attribute to string ***
    attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value:paragraphStyle, range:NSMakeRange(0, attributedString.length))
    attributedString.addAttribute(NSAttributedString.Key.font, value:font, range:NSMakeRange(0, attributedString.length))
    
    return attributedString
  }
  
  func setPlace(place: Place) {
    let post = place.post
    let text = NSMutableAttributedString(string: "")
    
    let boldFont = UIFont(name: "WorkSans-Bold", size: 16)
    let regularFont = UIFont(name: "Lato-Regular", size: 14)
    let name = place.name ?? ""
    let title = self.attributedText(text: String(format: "%@ ", name), font: boldFont!)

    text.append(title)

    var html = ""

    var content = [String]()

    let rating = post?.rating ?? 0
    if rating > 0 {
      var bell = ""
      for _ in 1 ... rating {
        bell = String(format: "%@ &#x1F514", bell)
      }
      content.append(bell)
    }

    for value in post?.price ?? [] {
      var dollars = [String]()
      if value > 0 {
        var dollar = ""
        for _ in 1 ... value {
          dollar = String(format: "%@$", dollar)
        }
        dollars.append(dollar)
      }
      content.append(dollars.joined(separator: ","))
    }

    var names : [String] = []
    for category in place.categories ?? [] {
      names.append(category.name)
    }
    for nabe in place.nabes ?? [] {
      names.append(nabe.name)
    }
    let categories = names.joined(separator: " | ")

    if let distance = place.distance {
      let milesAway = String(format: "%0.2f miles away", (distance/1609.344))
      self.milesAwayLabel.text = milesAway
    }

    html = content.joined(separator: "   &#8729   ")
    html = "\(html) <br> \(categories)"

    let blurb = try! NSMutableAttributedString(data: (html.data(using: String.Encoding.utf8))!, options: [NSAttributedString.DocumentReadingOptionKey.documentType : NSAttributedString.DocumentType.html], documentAttributes: nil)

    blurb.setAttributes([NSAttributedString.Key.font : regularFont!], range: NSMakeRange(0, blurb.length))
    text.append(blurb)

    self.textLabel.attributedText = text
    self.textLabel.lineBreakMode = .byTruncatingTail
    
    if let url = post?.imageURL {
      self.imageView.af_setImage(withURL: url)
    }
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
    self.textLabel.text = nil
    self.imageView.image = nil
  }
  
}