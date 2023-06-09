import UIKit

/*
 Ejercicio 5:
 Crea una función que devuelva, a un ID entregado, una estructura que contenga el nombre del artículo, su extracto (campo excerpt), su imagen destacada, el nombre del autor y su avatar.
 */

struct Articulo {
    let nombreArticulo: String
    let extracto: String
    let imagenDestacada: UIImage
    let nombreAutor: String
    let avatar: UIImage
}

func getInfo(id: Int) async throws -> Articulo? {
    guard let url = urlJSON else { throw NetworkError.urlNil }
    
    var postTitle = ""
    var postExtract = ""
    var postImageResult = UIImage()
    var postAuthor = ""
    var authorAv = UIImage()
    
    async let post = try await getJSON(url: url, type: [Posts].self).filter({ $0.id == id }).first
    
    guard let selectedPost = try await post else { return nil }
    
    async let aImage = try await getArticleImage(post: selectedPost)
    async let pAuthor = try await getPostAuthor(post: selectedPost)
    async let aAvatar = try await getAuthorAvatar(post: selectedPost)
    
    let (artIMG, postAuth, authAvatar, demoPost) = try await (aImage, pAuthor, aAvatar, post)
    
    if let artIMG, let postAuth, let authAvatar, let demoPost {
        postTitle = demoPost.title.rendered
        postExtract = demoPost.excerpt.rendered
        postImageResult = artIMG
        postAuthor = postAuth
        authorAv = authAvatar
    }
    
    return Articulo(nombreArticulo: postTitle,
                    extracto: postExtract,
                    imagenDestacada: postImageResult,
                    nombreAutor: postAuthor,
                    avatar: authorAv)
}
func getArticleImage(post: Posts) async throws -> UIImage? {
    do {
        guard let urlMedia = post._links.wpfeaturedmedia.first?.href else { throw NetworkError.urlNil }
        
        let media = try await getJSON(url: urlMedia, type: Media.self).guid.rendered.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        if let media = media,
           let imageURL = URL(string: media) {
            let mediaData = try Data(contentsOf: imageURL)
            
            return UIImage(data: mediaData)
        }
        
    } catch let error as NetworkError {
        print(error.description)
    } catch {
        print(error)
    }
    return nil
}

func getPostAuthor(post: Posts) async throws -> String? {
    var name: String?
    
    do {
        guard let href = post._links.author.first?.href else { return nil }
        name = try await getJSON(url: href, type: Author.self).name
    } catch let error as NetworkError {
        print(error.description)
    } catch {
        print(error)
    }
    
    return name
}

func getAuthorAvatar(post: Posts) async throws -> UIImage? {
    guard let urlMedia = post._links.author.first?.href else { throw NetworkError.urlNil }
    
    let imageMediaURL = try await getJSON(url: urlMedia, type: Author.self).avatar_urls._96
    
    let imageData = try Data(contentsOf: imageMediaURL)
    
    return UIImage(data: imageData)
}

Task {
    guard let info = try await getInfo(id: 1454) else { return }
    info.nombreArticulo
    info.nombreAutor
    info.extracto
    info.imagenDestacada
    info.avatar
}
