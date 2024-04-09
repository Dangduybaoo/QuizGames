import Foundation

// Define the user/player model
struct Player: Codable {
    let name: String
    var score: Int
}

// Define the leaderboard model
struct Leaderboard: Codable {
    var leaderboard: [Player]

    // Function to update leaderboard with a new player
    mutating func update(with player: Player) {
        leaderboard.append(player)
        leaderboard.sort { $0.score > $1.score }
    }
}

// Global variable for leaderboard
var leaderboard = Leaderboard(leaderboard: [])
let leaderboardFileURL = URL(fileURLWithPath: "Leaderboard.json")

// Define the question model
struct Question: Codable {
    let questionText: String
    let possibleAnswers: [String]
    let correctAnswerIndex: Int
    let difficultyLevel: Difficulty
    let category: String
}

// Define the difficulty enum
enum Difficulty: String, Codable {
    case easy
    case medium
    case hard
}

// Function to read the leaderboard from JSON file
func readLeaderboard(from fileURL: URL) -> Leaderboard? {
    do {
        let data = try Data(contentsOf: fileURL)
        let leaderboard = try JSONDecoder().decode(Leaderboard.self, from: data)
        return leaderboard
    } catch {
        print("\nError reading leaderboard from \(fileURL): \(error)")
        return nil
    }
}

// Function to write the leaderboard to JSON file
func writeLeaderboard(_ leaderboard: Leaderboard, to fileURL: URL) {
    do {
        let data = try JSONEncoder().encode(leaderboard)
        try data.write(to: fileURL)
        print("\nLeaderboard updated successfully.")
    } catch {
        print("\nError writing leaderboard to \(fileURL): \(error)")
    }
}

// Function to prompt player name entry
func getPlayerName() -> String {
    print("Enter your name: ", terminator: "")
    guard let name = readLine(), !name.isEmpty else {
        print("Invalid name. Please try again.")
        return getPlayerName()
    }
    return name
}

// Function to display the main menu
func displayMainMenu() {
    print("\n**********************")
    print("*      Quiz Game     *")
    print("*    1-Play Game     *")
    print("*    2-Review Scores *")
    print("*      3-Exit        *")
    print("**********************")
}

// Function to read questions from JSON file
func readQuestions(from fileURL: URL) -> [Question]? {
    do {
        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        let questionsData = try decoder.decode(QuestionData.self, from: data)
        return questionsData.questions
    } catch {
        print("\nError reading questions from \(fileURL): \(error)")
        return nil
    }
}

// Function to start the quiz game
func startGame(playerName: String) {
    print("\nChoose difficulty level:")
    print("1. Easy")
    print("2. Medium")
    print("3. Hard")
    print("\nEnter your choice (1-3): ", terminator: "\n")

    guard let difficultyChoice = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines),
          let difficultyInt = Int(difficultyChoice),
          (1...3).contains(difficultyInt) else {
        print("\nInvalid difficulty level. Please enter a number between 1 and 3.")
        return
    }

    let difficulty: Difficulty
    switch difficultyInt {
    case 1:
        difficulty = .easy
    case 2:
        difficulty = .medium
    case 3:
        difficulty = .hard
    default:
        fatalError("Invalid difficulty level. This should not happen.")
    }

    let questionsFileURL = URL(fileURLWithPath: "Question.json")

    if let questions = readQuestions(from: questionsFileURL) {
        let finalScore = playGame(questions: questions, difficulty: difficulty)
        print("\nYour final score: \(finalScore)")
        // Update leaderboard here based on final score
        let player = Player(name: playerName, score: finalScore)
        leaderboard.update(with: player)
        writeLeaderboard(leaderboard, to: leaderboardFileURL)
    } else {
        print("\nFailed to load questions.")
    }
}

// Function to display the leaderboard
func displayLeaderboard() {
    print("Leaderboard:")
    for (index, player) in leaderboard.leaderboard.enumerated() {
        print("\(index + 1). \(player.name) - Score: \(player.score)")
    }
}

// Structure to represent the JSON data
struct QuestionData: Codable {
    let questions: [Question]
}

// Function to present a single question to the user
func presentQuestion(_ question: Question) -> Bool {
    // Print the question
    print(question.questionText)

    // Print possible answers
    for (index, answer) in question.possibleAnswers.enumerated() {
        print("\(index + 1). \(answer)")
    }

    // Ask for user input
    print("\nEnter your answer (1-\(question.possibleAnswers.count)): ", terminator: "")
    if let userInput = readLine(), let userChoice = Int(userInput) {
        let userAnswerIndex = userChoice - 1
        if userAnswerIndex >= 0 && userAnswerIndex < question.possibleAnswers.count {
            if userAnswerIndex == question.correctAnswerIndex {
                print("\nCorrect!\n")
                return true
            } else {
                print("\nIncorrect!\n")
                return false
            }
        } else {
            print("\nInvalid answer. Please enter a number between 1 and \(question.possibleAnswers.count).")
            return false
        }
    } else {
        print("\nInvalid input.")
        return false
    }
}

// Function to play the game
func playGame(questions: [Question], difficulty: Difficulty) -> Int {
    var score = 0

    // Filter questions based on difficulty level
    let filteredQuestions = questions.filter { $0.difficultyLevel == difficulty }

    // Shuffle questions for random order
    let shuffledQuestions = filteredQuestions.shuffled()
    for question in shuffledQuestions {
        if presentQuestion(question) {
            score += 1
        }
    }

    return score
}

// Main program loop
var shouldQuit = false

// Initial prompt for player name entry
var playerName = getPlayerName()

// Load existing leaderboard data if available
if let existingLeaderboard = readLeaderboard(from: leaderboardFileURL) {
    leaderboard = existingLeaderboard
}

while !shouldQuit {
    displayMainMenu()

    print("\nEnter your choice: ", terminator: "")
    if let choice = readLine(), let option = Int(choice) {
        switch option {
        case 1:
            startGame(playerName: playerName)
        case 2:
            displayLeaderboard()
        case 3:
            shouldQuit = true
            print("\nExiting the game. Goodbye!")
        default:
            print("\nInvalid choice. Please enter a number.")
        }
    } else {
        print("\nInvalid input. Please enter a number.")
    }
}