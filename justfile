set dotenv-load

default:
	@just --list --unsorted

# Benchmark node recipes
mod node 'justmod/node.just'

# Driver node recipes
mod driver 'justmod/driver.just'

# Results recipes
mod results 'justmod/results.just'